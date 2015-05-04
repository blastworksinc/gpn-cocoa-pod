//
//  CPGpnView.h
//  CPGpnView
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

#import "CPView.h"
#import "CPGpnDisplayController.h"

@protocol CPInterstitialGpnAdViewDelegate;

@interface CPGpnView : CPView

@property (nonatomic, weak) id<CPInterstitialGpnAdViewDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL isModalShowing;
@property (nonatomic, readonly) CPGpnDisplayController  * displayController;

- (void)loadCreativeWithHTMLString:(NSString *)html baseURL:(NSURL *)url;
- (void)loadCreativeWithURLRequest:(NSURLRequest *)request;
- (void)stopLoading;
- (void)presentWithParams:(NSDictionary *)params;

- (void)firePresentingState; // TODO: refactor this

@end

/////////////////////////////////////////////////////////////////////////////

@protocol CPInterstitialGpnAdViewDelegate <NSObject>

@optional

// Called when the ad loads successfully.
- (void)adDidLoad:(CPGpnView *)adView;

// Called when the ad fails to load.
- (void)adDidFailToLoad:(CPGpnView *)adView withError:(NSError *)error;

// Called just after the ad page has been loaded.
- (void)adPageDidLoad:(CPGpnView *)adView;

// Called just after the ad page failed to load.
- (void)adPageDidFailToLoad:(CPGpnView *)adView withError:(NSError *)error;

- (void)ad:(CPGpnView *)adView didRequestCustomCloseEnabled:(BOOL)enabled;

- (void)adWillPresentModalView:(CPGpnView *)adView;

- (void)adDidPresentModalView:(CPGpnView *)adView;

- (void)adWillDismissModalView:(CPGpnView *)adView;

- (void)adDidDismissModalView:(CPGpnView *)adView;

@end
