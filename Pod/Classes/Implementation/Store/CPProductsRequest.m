//
//  CPProductsRequest.m
//  CPProductsRequest
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

#import "CPProductsRequest.h"

#import "CPCommon.h"

@interface CPProductsRequest () <SKProductsRequestDelegate>
{
    NSMutableSet     * _productsSet;
    NSTimeInterval     _delay;
    dispatch_queue_t   _queue;
    BOOL               _requesting;
}

@end

@implementation CPProductsRequest

- (id)initWithDelay:(NSTimeInterval)delay
{
    self = [super init];
    if (self)
    {
        _delay       = delay;
        _productsSet = [[NSMutableSet alloc] init];
        _queue       = dispatch_queue_create("com.gamehouse.CPProductsRequestQueue", 0);
    }
    return self;
}

- (void)dealloc
{
    
    dispatch_release(_queue);
    
}

- (void)addProductIdentifier:(NSString *)productIdentifier
{
    dispatch_async(_queue, ^{
        if (![_productsSet containsObject:productIdentifier])
        {
            [_productsSet addObject:productIdentifier];
            CPLogDebug(CPTagPurchase, @"Request product with identifier: %@", productIdentifier);
            
            if (!_requesting)
            {
                NSTimeInterval delay = _delay;
                
                #if CP_DEBUG_PURCHASE
                if (CPPurchaseDebugDelayProductsRequest > 0)
                {
                    CPLogWarn(CPTagPurchase, @"Debug override products request delay %f old value %f", CPPurchaseDebugDelayProductsRequest, delay);
                    delay = CPPurchaseDebugDelayProductsRequest;
                }
                #endif
                
                _requesting = YES;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
                dispatch_after(popTime, _queue, ^(void){
                    [self startRequest];
                });
                
                CPLogDebug(CPTagPurchase, @"Start product request in %f sec", delay);
            }
        }
    });
}

- (void)startRequest
{
    // wait until products request starts
    dispatch_sync(dispatch_get_main_queue(), ^{
        CPLogDebug(CPTagPurchase, @"Starting products request: %@", [[_productsSet allObjects] componentsJoinedByString:@","]);
        
        [self notifyDelegateDidStartRequestingProducts:[NSSet setWithSet:_productsSet]];
        
        #if CP_DEBUG_PURCHASE
        if (CPPurchaseDebugFlagShouldFailProductsRequest)
        {
            CPLogWarn(CPTagPurchase, @"Debug fail products request");
            return;
        }
        #endif
        
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:_productsSet];
        [request setDelegate:self];
        [request start];
    });
}

#pragma mark -
#pragma mark Delegate notifications

- (void)notifyDelegateDidReceiveProducts:(NSArray *)products
{
    if ([_delegate respondsToSelector:@selector(productsRequest:didReceiveProducts:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate productsRequest:self didReceiveProducts:products];
        });
    }
}

- (void)notifyDelegateDidStartRequestingProducts:(NSSet *)products
{
    if ([_delegate respondsToSelector:@selector(productsRequest:didStartRequestingProducts:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate productsRequest:self didStartRequestingProducts:products];
        });
    }
}

#pragma mark -
#pragma mark SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *responseProducts = response.products;
    
    dispatch_async(_queue, ^{
        NSMutableArray *products = [[NSMutableArray alloc] initWithCapacity:responseProducts.count];
        
        for (SKProduct *p in responseProducts)
        {
            CPAssert([_productsSet containsObject:p.productIdentifier]);
            [_productsSet removeObject:p.productIdentifier];
            
            CPProduct *product = [[CPProduct alloc] initWithSKProduct:p];
            [products addObject:product];
        }
        
        [self notifyDelegateDidReceiveProducts:products];
        
        _requesting = NO;
    });
}

@end
