//
//  CrossPromotion_Internal.h
//  CrossPromotion_Internal
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

#import "CrossPromotion.h"
#import "CrossPromotion_Debug.h"

#import "CPInterstitialAdView.h"
#import "CPReachability.h"

#import "CPServerApi.h"
#import "CPPurchaseTracker.h"
#import "CPHttpRequestManager.h"

extern NSString * const CrossPromotionSettingsDidUpdateNotification;
extern NSString * const CrossPromotionSettingsDidUpdateNotificationKeySettings;

extern BOOL CPConfigOverrideWindowLevel;
extern BOOL CPConfigNeedsTransformForViewInWindow;

@interface CrossPromotion (Internal)

@property (nonatomic, readonly) CPInterstitialAdView * interstitialAdView;
@property (nonatomic, readonly) CPServerApi          * serverApi;
@property (nonatomic, readonly) CPPurchaseTracker    * purchaseTracker;
@property (nonatomic, readonly) CPHttpRequestManager * requestManager;

- (NSTimeInterval)timerIntervalSinceAppStart;

+ (void)overrideDefaultServerURL:(NSString *)serverURL;
+ (void)setConfigOverrideWindowLevel:(BOOL)flag;
+ (void)setConfigNeedsTransformForViewInWindow:(BOOL)flag;

+ (void)setWrapperName:(NSString *)name;
+ (void)setWrapperVersion:(NSString *)version;

@end

@interface CrossPromotion (Reachability)

- (CPNetworkStatus)currentNetworkStatus;
- (NSString *)currentNetworkStatusString;

@end
