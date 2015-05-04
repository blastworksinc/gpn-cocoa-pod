//
//  CPPurchaseTracker.h
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

#import <Foundation/Foundation.h>

@class CPConcurrentList;
@class CPPayment;
@class CPProductRegistry;
@class CPProductsRequest;
@class CPPurchaseTrackerSettings;

#ifndef CP_PURCHASE_TRACKER_H__
#define CP_PURCHASE_TRACKER_H__

// this is a weird Marmalade SDK bug:
// we can't use 'extern NSString * const' because
// when building under Windows, some of the constants turn
// to be nil. Defines work fine.

#define CPPurchaseTrackerWillRestoreNotification            @"com.gamehouse.RestoringPurchasesNotification"
#define CPPurchaseTrackerPurchaseDidQueueNotification       @"com.gamehouse.PurchaseQueuedNotification"
#define CPPurchaseTrackerPurchaseWillTrackNotification      @"com.gamehouse.PurchaseWillTrackNotification"
#define CPPurchaseTrackerPurchaseDidTrackNotification       @"com.gamehouse.PurchaseDidTrackNotification"

#define CPPurchaseTrackerWillRequestProductsNotification    @"com.gamehouse.WillRequestProductsNotification"
#define CPPurchaseTrackerDidReceiveProductsNotification     @"com.gamehouse.DidReceiveProductsNotification"

#define CPPurchaseTrackerDidChangePaymentsNotification      @"com.gamehouse.DidChangePaymentsNotification"
#define CPPurchaseTrackerDidChangePurchasesNotification     @"com.gamehouse.DidChangePurchasesNotification"

#define CPPurchaseTrackerDidRemoveOldItemNotification       @"com.gamehouse.DidRemoveOldItem"
#define CPPurchaseTrackerDidRemoveQueuedItemNotification    @"com.gamehouse.DidRemoveQueuedItem"

#define CPPurchaseTrackerNotificationKeyPurchase            @"Purchase"
#define CPPurchaseTrackerNotificationKeySucceedFlag         @"SucceedFlag"
#define CPPurchaseTrackerNotificationKeyProducts            @"Products"
#define CPPurchaseTrackerNotificationKeyPurchases           @"Purchases"
#define CPPurchaseTrackerNotificationKeyPayments            @"Payments"
#define CPPurchaseTrackerNotificationKeyItem                @"Item"

#define CPPurchaseTrackerProductsFile                       @"gpn-store-products.bin"
#define CPPurchaseTrackerPaymentsFile                       @"gpn-store-payments.bin"
#define CPPurchaseTrackerPurchasesFile                      @"gpn-store-purchases.bin"

#endif // CP_PURCHASE_TRACKER_H__

@interface CPPurchaseTracker : NSObject

@property (nonatomic, readonly) CPProductRegistry * productRegistry;

@property (nonatomic, readonly) CPConcurrentList  * payments;
@property (nonatomic, readonly) CPConcurrentList  * purchases;
@property (nonatomic, readonly) CPConcurrentList  * processingPurchases;

@property (nonatomic, readonly) NSOperationQueue  * trackingQueue;
@property (nonatomic, readonly) BOOL isTracking;

@property (nonatomic, readonly) CPProductsRequest * productsRequest;

- (id)initWithSettings:(CPPurchaseTrackerSettings *)settings;

- (void)queuePayment:(CPPayment *)payment;
- (void)restore;
- (void)stop;

@end
