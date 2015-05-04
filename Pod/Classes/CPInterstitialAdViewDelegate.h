//
//  CPInterstitialAdViewDelegate.h
//  CPInterstitialAdViewDelegate
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

#import <UIKit/UIKit.h>

typedef enum {
    CPInterstitialResultPresented = 0,
    CPInterstitialResultNotPresented,
    CPInterstitialResultNotPresentedForbidsPosition,
} CPInterstitialResult;

@class CPInterstitialAdView;

@protocol CPInterstitialAdViewDelegate <NSObject>

@optional
// Interstitial ad is received: it’s safe to present it now.
- (void)interstitialAdDidReceive:(CPInterstitialAdView *)adView;

//  Interstitial ad is failed to receive.
- (void)interstitialAdDidFail:(CPInterstitialAdView *)adView withError:(NSError *)error;

// Interstitial ad will present full screen modal view.
- (void)interstitialAdWillOpen:(CPInterstitialAdView *)adView;

// Interstitial ad did present full screen modal view. You can pause your game here.
- (void)interstitialAdDidOpen:(CPInterstitialAdView *)adView;

// Interstitial ad will hide full screen modal view.
- (void)interstitialAdWillClose:(CPInterstitialAdView *)adView;

// Interstitial ad did hide full screen modal view. You can resume your game here.
- (void)interstitialAdDidClose:(CPInterstitialAdView *)adView;

// Return YES if ad should be destroyed on a low memory warning.
- (BOOL)interstitialAdShouldDestroyOnLowMemory;

// Interstitial ad was destroyed after receiving low memory warning.
- (void)interstitialAdLowMemoryDidDestroy;

// Optional parameters to be passed with ad request.
- (NSDictionary *)interstitialAdParams;

@end
