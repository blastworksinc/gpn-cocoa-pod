//
//  CPPurchaseTracker.m
//  CPPurchaseTracker
//
//  Copyright 2015 GameHouse, a division of RealNetworks, Inc.
// 
//  The GameHouse Promotion Network SDK is licensed under the Apache License, 
//  Version 2.0 (the "License"); you may not use this file except in compliance 
//  with the License. You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <StoreKit/StoreKit.h>

#import "CPPurchaseTracker.h"
#import "CPPurchaseTrackerConstants.h"

#import "CPCommon.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

static NSString * const CPRequestParamProductId           = @"product[identifier]";
static NSString * const CPRequestParamProductPrice        = @"product[price]";
static NSString * const CPRequestParamProductPriceLocale  = @"product[price_locale]";

static NSString * const CPRequestParamPaymentDate         = @"payment[date]";
static NSString * const CPRequestParamPaymentQuantity     = @"payment[quantity]";

static const NSTimeInterval CPProductsRequestDelay        = 5.0;

@interface CPPurchaseTracker () <CPProductsRequestDelegate>
{
    CPProductRegistry * _productRegistry;
    
    CPConcurrentList  * _payments;
    CPConcurrentList  * _purchases;
    CPConcurrentList  * _processingPurchases;
    
    NSOperationQueue  * _trackingQueue;
    BOOL _isTracking;
}

// this property should be atomic since it's value is accessed and modified from different threads
@property (atomic, strong) CPPurchaseTrackerSettings * settings;

@end

@implementation CPPurchaseTracker

- (id)initWithSettings:(CPPurchaseTrackerSettings *)settings
{
    self = [super init];
    if (self)
    {
        _settings = settings;
        
        NSString *productsFile  = CPGetAppSupportDirectorySubpath(CPPurchaseTrackerProductsFile, YES);
        NSString *paymentsFile  = CPGetAppSupportDirectorySubpath(CPPurchaseTrackerPaymentsFile, YES);
        NSString *purchasesFile = CPGetAppSupportDirectorySubpath(CPPurchaseTrackerPurchasesFile, YES);
        
        _productRegistry = [[CPProductRegistry alloc] initWithContentsOfFile:productsFile];
        _payments  = [[CPConcurrentList alloc] initWithStoragePath:paymentsFile];
        _purchases = [[CPConcurrentList alloc] initWithStoragePath:purchasesFile];
        _processingPurchases = [[CPConcurrentList alloc] init]; // don't store processing purchase
        
        _trackingQueue = [[NSOperationQueue alloc] init];
        _trackingQueue.maxConcurrentOperationCount = 1;
        
        [self registerObservers];
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

#pragma mark -
#pragma mark Stop

- (void)stop
{
    [self unregisterObservers];
    
    [_productsRequest setDelegate:nil];
    
    [_payments cancelAllOperations];
    [_purchases cancelAllOperations];
    [_processingPurchases cancelAllOperations];
    [_trackingQueue cancelAllOperations];
}

#pragma mark -
#pragma mark Restore

- (void)restore
{
    #if CP_DEBUG_PURCHASE
    [self postNoficationName:CPPurchaseTrackerWillRestoreNotification];
    #endif
    
    // restore purchases
    if ([self canProcessPurchase])
    {
        [self restorePurchases];
    }
    
    // restore payments
    [self restorePayments];
}

- (void)restorePurchases
{
    [_purchases asyncDispatchBlock:^(CPConcurrentList *list) {
        // trim cache and remove old items
        [self adjustCacheList:list];
        
        // process remaining items
        for (CPPurchase *purchase in list.array)
        {
            [self processPurchase:purchase];
        }
    }];
}

- (void)restorePayments
{
    [_payments asyncDispatchBlock:^(CPConcurrentList *list) {
        // trim cache and remove old items
        [self adjustCacheList:list];
        
        // process remaining items
        if (list.count > 0)
        {
            NSMutableArray *processed = [[NSMutableArray alloc] initWithCapacity:list.count];
            
            for (CPPayment *payment in list.array)
            {
                CPProduct *product = [self findProductWithIdentifier:payment.productIdentifier];
                if (product != nil)
                {
                    CPPurchase *purchase = [[CPPurchase alloc] initWithProduct:product andPayment:payment];
                    [self queuePurchase:purchase];
                    
                    [processed addObject:payment];
                    CPLogDebug(CPTagPurchase, @"Payment processed: %@", payment);
                }
                else
                {
                    [self requestProductInfoWithId:payment.productIdentifier];
                }
            }
            
            if (processed.count > 0)
            {
                for (int i = processed.count-1; i >= 0; --i)
                {
                    CPPayment *payment = [processed objectAtIndex:i];
                    [list.array removeObject:payment];
                }
                [list synchronize];
            }
            
        }
    }];
}

- (BOOL)adjustCacheList:(CPConcurrentList *)list
{
    BOOL modified = NO;
    
    NSMutableArray *array = list.array;
    
    // trim to size
    NSInteger cacheSize = self.settings.cache_size;
    
    // override value
    #if CP_DEBUG_PURCHASE
    if (CPPurchaseDebugFlagShouldOverrideCacheSize)
    {
        NSInteger oldCacheSize = cacheSize;
        cacheSize = CPPurchaseDebugOverridenCacheSize;
        
        CPLogWarn(CPTagPurchase, @"Debug override cache size: %d old size %d", cacheSize, oldCacheSize);
    }
    #endif
    
    if (cacheSize > 0)
    {
        modified |= [self array:array trimToSize:cacheSize]; // should be accessed with 'atomic' property
    }
    
    // remove old items
    NSTimeInterval cacheAge = self.settings.cache_age_seconds;
    
    // override value
    #if CP_DEBUG_PURCHASE
    if (CPPurchaseDebugFlagShouldOverrideCacheAge)
    {
        NSTimeInterval oldCacheAge = cacheAge;
        cacheAge = CPPurchaseDebugOverridenCacheAge;
        
        CPLogWarn(CPTagPurchase, @"Debug override cache age: %f old age %f", cacheAge, oldCacheAge);
    }
    #endif
    
    if (cacheAge > 0)
    {
        modified |= [self array:array removeItemsOlderThanAge:cacheAge]; // should be accessed with 'atomic' property
    }
    
    // save changes
    if (modified)
    {
        [list synchronize];
    }
    
    return modified;
}

- (BOOL)array:(NSMutableArray *)items removeItemsOlderThanAge:(NSTimeInterval)age
{
    BOOL modified = NO;
    SEL ageSelector = @selector(age);
    
    for (int i = items.count-1; i >= 0; --i)
    {
        id item = [items objectAtIndex:i];
        if ([item respondsToSelector:ageSelector])
        {
            NSTimeInterval itemAge = [item age];
            if (itemAge > age)
            {
                [items removeObjectAtIndex:i];
                modified = YES;
                
                CPLogDebug(CPTagPurchase, @"Removed item with age %f: %@", itemAge, item);
                
                #if CP_DEBUG_PURCHASE
                [self postNoficationName:CPPurchaseTrackerDidRemoveOldItemNotification userInfo:@{
                    CPPurchaseTrackerNotificationKeyItem : item
                }];
                #endif
            }
        }
        else
        {
            CPAssert([item respondsToSelector:ageSelector]);
        }
    }
    
    return modified;
}

- (BOOL)array:(NSMutableArray *)array trimToSize:(NSInteger)size
{
    int deleteCount = array.count - size;
    if (deleteCount > 0)
    {
        #if CP_DEBUG_PURCHASE
        for (int i = 0; i < deleteCount; ++i)
        {
            [self postNoficationName:CPPurchaseTrackerDidRemoveQueuedItemNotification userInfo:@{
                CPPurchaseTrackerNotificationKeyItem : [array objectAtIndex:i]
             }];
        }
        #endif
        
        NSRange deleteRange = NSMakeRange(0, deleteCount);
        [array removeObjectsInRange:deleteRange];
        
        return YES;
    }
    
    return NO;
}

#pragma mark -
#pragma mark Purchase queue

- (void)queuePurchase:(CPPurchase *)purchase
{
    #if CP_DEBUG_PURCHASE
    [self postNoficationName:CPPurchaseTrackerPurchaseDidQueueNotification userInfo:@{
        CPPurchaseTrackerNotificationKeyPurchase : purchase
     }];
    #endif
    
    [_purchases asyncAddObject:purchase withCallback:^(CPConcurrentList *list) {
        
        // trim cache and remove old items
        [self adjustCacheList:list];
        
        // debug notification
        #if CP_DEBUG_PURCHASE
        [self postNoficationName:CPPurchaseTrackerDidChangePurchasesNotification userInfo:@{
            CPPurchaseTrackerNotificationKeyPurchases : list.array
        }];
        #endif
        
        if ([self canProcessPurchase])
        {
            CPLogDebug(CPTagPurchase, @"Added unprocessed purchase (total: %d): %@", list.count, purchase);
            [self processPurchase:purchase];
        }
    }];
}

- (void)processPurchase:(CPPurchase *)purchase
{
    [_processingPurchases asyncAddObject:purchase withCallback:^(CPConcurrentList *list) {
        CPLogDebug(CPTagPurchase, @"Added processing purchase (total: %d): %@", list.count, purchase);
        [self processPurchasesList:list];
    }];
}

- (void)processPurchasesList:(CPConcurrentList *)list
{
    if ([self canProcessPurchase])
    {
        if (_isTracking)
        {
            CPLogDebug(CPTagPurchase, @"Purchase tracking is in progress");
        }
        else
        {
            CPPurchase *purchase = [list peekSync];
            if (purchase != nil)
            {
                _isTracking = YES;
                [self asyncTrackPurchase:purchase];
            }
        }
    }
    else
    {
        CPAssert([self canProcessPurchase]);
    }
}

- (void)asyncTrackPurchase:(CPPurchase *)purchase
{
    [_trackingQueue addOperationWithBlock:^{
        CPLogDebug(CPTagPurchase, @"Sync tracking purchase: %@", purchase);
        [self syncTrackPurchase:purchase];
    }];
}

- (void)syncTrackPurchase:(CPPurchase *)purchase
{
    #if CP_DEBUG_PURCHASE
    [self postNoficationName:CPPurchaseTrackerPurchaseWillTrackNotification userInfo:@{
        CPPurchaseTrackerNotificationKeyPurchase : purchase
     }];
    #endif
    
    CPServerApi *serverApi = [CrossPromotion sharedInstance].serverApi;
    CPAssert(serverApi != nil);
    
    NSString *appId = [CrossPromotion sharedInstance].appId;
    
    NSURL *trackingURL = self.settings.tracking_pixel_url; // should be accessed with 'atomic' property
    CPAssert(trackingURL);
    
    if (!trackingURL)
    {
        CPLogError(CPTagPurchase, @"Can't process purchases list: tracking URL is not defined yet");
        [self requestDidFailTrackingPurchase:purchase];
        return;
    }
    
    NSDictionary *params = [self createRequestParamsForTransaction:purchase];
    CPAssert(params);
    
    if (!params)
    {
        CPLogError(CPTagPurchase, @"Can't process purchases list: failed to create request params");
        [self requestDidFailTrackingPurchase:purchase];
        return;
    }
    
    NSURLRequest *request = [serverApi createPurchaseTrackingRequestWithAppId:appId trackingURL:trackingURL andParams:params];
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    #if CP_DEBUG_PURCHASE
    NSTimeInterval debugDelay = CPPurchaseDebugDelayTrackingRequest;
    if (debugDelay > 0)
    {
        CPLogWarn(CPTagPurchase, @"Debug delay tracking request: %f", debugDelay);
        [NSThread sleepForTimeInterval:debugDelay];
    }
    
    if (CPPurchaseDebugFlagShouldFailTrackingRequest)
    {
        CPLogWarn(CPTagPurchase, @"Debug fail tracking request");
        [self requestDidFailTrackingPurchase:purchase];
        return;
    }
    else if (CPPurchaseDebugFlagShouldSucceedTrackingRequest)
    {
        CPLogWarn(CPTagPurchase, @"Debug succeed tracking request");
        [self requestDidFinishTrackingPurchase:purchase];
        return;
    }
    #endif
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error != nil)
    {
        CPLogError(CPTagPurchase, @"Transaction request did fail: %@", error);
        [self requestDidFailTrackingPurchase:purchase];
    }
    else if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200)
        {
            CPLogDebug(CPTagPurchase, @"Transaction request did finish");
            [self requestDidFinishTrackingPurchase:purchase];
        }
        else
        {
            CPLogError(CPTagPurchase, @"Transaction request did fail with status code: %d", httpResponse.statusCode);
            [self requestDidFailTrackingPurchase:purchase];
        }
    }
    else
    {
        CPLogDebug(CPTagPurchase, @"Transaction request did finish");
        [self requestDidFinishTrackingPurchase:purchase];
    }
}

- (void)requestDidFailTrackingPurchase:(CPPurchase *)purchase
{
    #if CP_DEBUG_PURCHASE
    [self postNoficationName:CPPurchaseTrackerPurchaseDidTrackNotification userInfo:@{
        CPPurchaseTrackerNotificationKeyPurchase : purchase,
        CPPurchaseTrackerNotificationKeySucceedFlag : @NO
    }];
    #endif
    
    [self didFinishProcessingPurchase:purchase];
}

- (void)requestDidFinishTrackingPurchase:(CPPurchase *)purchase
{
    #if CP_DEBUG_PURCHASE
    [self postNoficationName:CPPurchaseTrackerPurchaseDidTrackNotification userInfo:@{
        CPPurchaseTrackerNotificationKeyPurchase : purchase,
        CPPurchaseTrackerNotificationKeySucceedFlag : @YES
    }];
    #endif
    
    [_purchases asyncRemoveObject:purchase withCallback:^(CPConcurrentList *list) {
        
        #if CP_DEBUG_PURCHASE
        [self postNoficationName:CPPurchaseTrackerDidChangePurchasesNotification userInfo:@{
            CPPurchaseTrackerNotificationKeyPurchases : list.array
        }];
        #endif
        
        CPLogDebug(CPTagPurchase, @"Remove unprocessed purchase (total: %d)", list.count, purchase);
        [self didFinishProcessingPurchase:purchase];
    }];
}

- (void)didFinishProcessingPurchase:(CPPurchase *)purchase
{
    CPAssert([self canProcessPurchase]);
    
    [_processingPurchases asyncRemoveObject:purchase withCallback:^(CPConcurrentList *list) {
        _isTracking = NO;
        CPLogDebug(CPTagPurchase, @"Remove processing purchase (total: %d)", list.count, purchase);
        [self processPurchasesList:list];
    }];
}

- (NSDictionary *)createRequestParamsForTransaction:(CPPurchase *)transaction
{
    CPProduct *product = transaction.product;
    CPPayment *payment = transaction.payment;
    
    NSString *timestamp = CPRFC3339StringForDate(payment.date);
    CPAssert(timestamp);
    
    if (timestamp == nil)
    {
        return nil;
    }
    
    NSDictionary *params = @{
        CPRequestParamProductId          : product.identifier,
        CPRequestParamProductPrice       : product.price,
        CPRequestParamProductPriceLocale : product.priceLocale.localeIdentifier,
         
        CPRequestParamPaymentDate        : timestamp,
        CPRequestParamPaymentQuantity    : [NSNumber numberWithInteger:payment.quantity],
    };
    return params;
}

#pragma mark -
#pragma mark Payment queue

- (void)queuePayment:(CPPayment *)payment
{
    [_payments asyncDispatchBlock:^(CPConcurrentList *list) {
        CPProduct *product = [self findProductWithIdentifier:payment.productIdentifier];
        if (product != nil)
        {
            CPPurchase *purchase = [[CPPurchase alloc] initWithProduct:product andPayment:payment];
            [self queuePurchase:purchase];
        }
        else
        {
            [list addObject:payment];
            
            // trim cache and remove old items
            [self adjustCacheList:list];
            
            // there might be no items after the queue is adjusted
            if (list.count > 0)
            {
                #if CP_DEBUG_PURCHASE
                [self postNoficationName:CPPurchaseTrackerDidChangePaymentsNotification userInfo:@{
                    CPPurchaseTrackerNotificationKeyPayments : [NSArray arrayWithArray:list.array]
                }];
                #endif
                
                CPLogDebug(CPTagPurchase, @"Added unprocessed payment (total: %d): %@", list.count, payment);
                [self requestProductInfoWithId:payment.productIdentifier];
            }
        }
    }];
}

- (CPProduct *)findProductWithIdentifier:(NSString *)productIdentifier
{
    CPAssert(_productRegistry);
    return [_productRegistry findProductWithIdentifier:productIdentifier];
}

- (void)registerProduct:(CPProduct *)product
{
    CPAssert(_productRegistry);
    return [_productRegistry registerProduct:product];
}

- (void)saveProducts
{
    [_productRegistry synchronize];
}

- (void)requestProductInfoWithId:(NSString *)productIdentifier
{
    if (_productsRequest == nil)
    {
        _productsRequest = [[CPProductsRequest alloc] initWithDelay:CPProductsRequestDelay];
        _productsRequest.delegate = self;
    }
    
    [_productsRequest addProductIdentifier:productIdentifier];
}

#pragma mark -
#pragma mark CPProductsRequestDelegate

- (void)productsRequest:(CPProductsRequest *)request didStartRequestingProducts:(NSSet *)products
{
    #if CP_DEBUG_PURCHASE
    [self postNoficationName:CPPurchaseTrackerWillRequestProductsNotification userInfo:@{
        CPPurchaseTrackerNotificationKeyProducts : products
    }];
    #endif
}

- (void)productsRequest:(CPProductsRequest *)request didReceiveProducts:(NSArray *)products
{
    #if CP_DEBUG_PURCHASE
    [self postNoficationName:CPPurchaseTrackerDidReceiveProductsNotification userInfo:@{
        CPPurchaseTrackerNotificationKeyProducts : products
    }];
    #endif
    
    [_payments asyncDispatchBlock:^(CPConcurrentList *list) {
        NSInteger removedCount = 0;
        for (CPProduct *product in products)
        {
            [self registerProduct:product];
            
            NSMutableArray *payments = list.array;
            for (int i = payments.count - 1; i >= 0; --i)
            {
                CPPayment *payment = [payments objectAtIndex:i];
                if ([payment.productIdentifier isEqualToString:product.identifier])
                {
                    CPPurchase *purchase = [[CPPurchase alloc] initWithProduct:product andPayment:payment];
                    [self queuePurchase:purchase];
                    
                    [payments removeObjectAtIndex:i];
                    ++removedCount;
                    CPLogDebug(CPTagPurchase, @"Remove unprocessed payment (total: %d)", list.count, purchase);
                }
            }
        }
        
        // synchronize the list if payments changed
        if (removedCount != 0)
        {
            [list synchronize];
            
            #if CP_DEBUG_PURCHASE
            [self postNoficationName:CPPurchaseTrackerDidChangePaymentsNotification userInfo:@{
                CPPurchaseTrackerNotificationKeyPayments : [NSArray arrayWithArray:list.array]
             }];
            #endif
        }
        
        [self saveProducts];
    }];
}

#pragma mark -
#pragma mark Notification

- (void)registerObservers
{
    CP_OBSERVERS_ADD(CrossPromotionSettingsDidUpdateNotification, @selector(settingsDidUpdateNotification:));
}

- (void)unregisterObservers
{
    CP_OBSERVERS_REMOVE(CrossPromotionSettingsDidUpdateNotification);
}

- (void)settingsDidUpdateNotification:(NSNotification *)notification
{
    CPSettings *globalSettings = CPObjectForKeyAndClass([notification userInfo], CrossPromotionSettingsDidUpdateNotificationKeySettings, [CPSettings class]);
    
    CPAssert(globalSettings);
    CPAssert(globalSettings.iap);
    
    if (globalSettings.iap)
    {
        self.settings = globalSettings.iap; // should be set with 'atomic' property
    }
}

#pragma mark -
#pragma mark Helpers

- (BOOL)canProcessPurchase
{
    return self.settings.tracking_pixel_url != nil; // should be accessed with 'atomic' property
}

- (void)postNoficationName:(NSString *)name
{
    [self postNoficationName:name userInfo:nil];
}

- (void)postNoficationName:(NSString *)name userInfo:(NSDictionary *)userInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
    });
}

@end

#pragma clang diagnostic pop