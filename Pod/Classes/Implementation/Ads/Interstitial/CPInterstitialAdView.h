//
//  CPInterstitialAdView.h
//  CPInterstitialAdView
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

#import "CPBaseAdView.h"
#import "CPInterstitialAdViewDelegate.h"

@interface CPInterstitialAdView : CPBaseAdView

@property (nonatomic, weak) id<CPInterstitialAdViewDelegate> delegate;

@property (nonatomic, strong) NSArray * includesPositions;
@property (nonatomic, strong) NSArray * excludesPositions;

@property (nonatomic, readonly) NSString * stateName;

- (void)loadRequest:(NSURLRequest *)request;
- (CPInterstitialResult)presentWithParams:(NSDictionary *)params;
- (void)hide;
- (void)forceClose;

- (BOOL)isLoading;
- (BOOL)isLoaded;
- (BOOL)isPresented;
- (BOOL)isPresenting;
- (BOOL)isHidding;

@end
