//
//  CPInterstitialAdView.m
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

#import "CPInterstitialAdView_Internal.h"
#import "CPBaseAdView_Inheritance.h"

#import "CPGpnView.h"
#import "CPCommon.h"

typedef enum {
    CPInterstitialAdViewStateNotLoaded,
    CPInterstitialAdViewStateLoading,
    CPInterstitialAdViewStateLoaded,
    CPInterstitialAdViewStateFailed,
    CPInterstitialAdViewStatePresenting, // "present" is called but the ad is not fully visible yet
    CPInterstitialAdViewStatePresented,  // the ad is fully visible
    CPInterstitialAdViewStateHidding,    // "hide" is called but the ad is still visible (animation is played)
    CPInterstitialAdViewStateHidden,     // the ad is gone
} CPInterstitialAdViewState;

@interface CPInterstitialAdView() <CPInterstitialGpnAdViewDelegate>

@property (nonatomic, strong, readwrite) CPGpnView * adView;
@property (nonatomic, assign, readwrite) CPInterstitialAdViewState state;

@end

@implementation CPInterstitialAdView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _adView = [[CPGpnView alloc] initWithFrame:self.bounds];
        _adView.delegate = self;
        [self addSubview:_adView];
        
        [self setState:CPInterstitialAdViewStateNotLoaded];
    }
    return self;
}

- (void)dealloc
{
    self.adView.delegate = nil;
    
    
}

- (CPInterstitialResult)presentWithParams:(NSDictionary *)params
{
    // should notify the adview about presenting state as soon as possible
    [self.adView firePresentingState];
    
    if ([self isLoaded])
    {
        NSString *position = [params objectForKey:@"position"];
        if (position != nil && ![self isPositionAllowed:position])
        {
            CPLogWarn(CPTagCommon, @"Position is not allowed: '%@'", position);
            return CPInterstitialResultNotPresentedForbidsPosition;
        }
        
        [self.adView presentWithParams:params];
        [self start];
        
        return CPInterstitialResultPresented;
    }
    
    return CPInterstitialResultNotPresented;
}

- (void)hide
{
    if ([self isPresented] || [self isPresenting]) {
        [self.adView.displayController close];
    }
}

- (void)forceClose
{
    if ([self isPresented] || [self isPresenting] || [self isHidding]) {
        BOOL callWillDismiss = ![self isHidding]; // shouldn't call this twice
        [self.adView.displayController forceCloseCallWillDismiss:callWillDismiss callDidDismissClose:YES];
    }
}

#pragma mark -
#pragma mark Positions

- (BOOL)isPositionAllowed:(NSString *)position
{
    if (_excludesPositions.count > 0 && [_excludesPositions containsObject:position])
    {
        return NO;
    }
    
    if (_includesPositions.count > 0 && ![_includesPositions containsObject:position])
    {
        return NO;
    }
    
    return YES;
}

#pragma mark -
#pragma mark Content

- (void)loadRequest:(NSURLRequest *)request
{
    [self setState:CPInterstitialAdViewStateLoading];
    
    [super loadContent];
    [_adView loadCreativeWithURLRequest:request];
}

- (void)cancelLoadContent
{
    [self setState:CPInterstitialAdViewStateFailed];
    
    [_adView stopLoading];
    [super cancelLoadContent];
}

- (void)contentDidLoad
{
    [self setState:CPInterstitialAdViewStateLoaded];
    
    [super contentDidLoad];
    [self notifyDelegateDidReceive];
}

- (void)contentDidFailWithError:(NSError *)error
{
    [self setState:CPInterstitialAdViewStateFailed];
    
    [super contentDidFailWithError:error];
    [self notifyDelegateDidFailWithError:error];
}

#pragma mark -
#pragma mark State

- (void)setState:(CPInterstitialAdViewState)state
{
    _state = state;
    CPLogDebug(CPTagCommon, @"Interstitial ad view state: %@", self.stateName);
}

- (BOOL)isLoading
{
    return _state == CPInterstitialAdViewStateLoading;
}

- (BOOL)isLoaded
{
    return _state == CPInterstitialAdViewStateLoaded;
}

- (BOOL)isPresented
{
    return _state == CPInterstitialAdViewStatePresented;
}

- (BOOL)isPresenting
{
    return _state == CPInterstitialAdViewStatePresenting;
}

- (BOOL)isHidding
{
    return _state == CPInterstitialAdViewStateHidding;
}

#pragma mark -
#pragma mark InterstitialDelegate

- (void)notifyDelegateDidReceive
{
    CPLogInfo(CPTagCallbacks, @"Interstitial Ad did receive");
    
    if ([_delegate respondsToSelector:@selector(interstitialAdDidReceive:)])
    {
        [_delegate interstitialAdDidReceive:self];
    }
}

- (void)notifyDelegateDidFailWithError:(NSError *)error
{
    CPLogError(CPTagCallbacks, @"Interstitial Ad did fail with error: %@", [error description]);
    
    if ([_delegate respondsToSelector:@selector(interstitialAdDidFail:withError:)])
    {
        [_delegate interstitialAdDidFail:self withError:error];
    }
}

- (void)notifyDelegateWillOpen
{
    CPLogInfo(CPTagCallbacks, @"Interstitial Ad will open");
    
    if ([_delegate respondsToSelector:@selector(interstitialAdWillOpen:)])
    {
        [_delegate interstitialAdWillOpen:self];
    }
}

- (void)notifyDelegateDidOpen
{
    CPLogInfo(CPTagCallbacks, @"Interstitial Ad did open");
    
    if ([_delegate respondsToSelector:@selector(interstitialAdDidOpen:)])
    {
        [_delegate interstitialAdDidOpen:self];
    }
}

- (void)notifyDelegateWillClose
{
    CPLogInfo(CPTagCallbacks, @"Interstitial Ad will close");
    
    if ([_delegate respondsToSelector:@selector(interstitialAdWillClose:)])
    {
        [_delegate interstitialAdWillClose:self];
    }
}

- (void)notifyDelegateDidClose
{
    CPLogInfo(CPTagCallbacks, @"Interstitial Ad did close");
    
    if ([_delegate respondsToSelector:@selector(interstitialAdDidClose:)])
    {
        [_delegate interstitialAdDidClose:self];
    }
}

#pragma mark -
#pragma mark CPInterstitialGpnAdViewDelegate

// Called when the ad loads successfully.
- (void)adDidLoad:(CPGpnView *)adView
{
    [self contentDidLoad];
}

// Called when the ad fails to load.
- (void)adDidFailToLoad:(CPGpnView *)adView withError:(NSError *)error
{
    [self contentDidFailWithError:error];
}

- (void)adPageDidLoad:(CPGpnView *)adView
{
}

- (void)adWillPresentModalView:(CPGpnView *)adView
{
    [self setState:CPInterstitialAdViewStatePresenting];
    [self notifyDelegateWillOpen];
}

- (void)adDidPresentModalView:(CPGpnView *)adView
{
    [self setState:CPInterstitialAdViewStatePresented];
    [self notifyDelegateDidOpen];
}

- (void)adWillDismissModalView:(CPGpnView *)adView
{
    [self setState:CPInterstitialAdViewStateHidding];
    [self notifyDelegateWillClose];
}

- (void)adDidDismissModalView:(CPGpnView *)adView
{
    [self setState:CPInterstitialAdViewStateHidden];
    [self notifyDelegateDidClose];
}

#pragma mark -
#pragma mark Properties

- (NSString *)stateName
{
    switch (_state) {
        case CPInterstitialAdViewStateNotLoaded:
            return @"notloaded";
        case CPInterstitialAdViewStateLoading:
            return @"loading";
        case CPInterstitialAdViewStateLoaded:
            return @"loaded";
        case CPInterstitialAdViewStateFailed:
            return @"failed";
        case CPInterstitialAdViewStatePresented:
            return @"presented";
        case CPInterstitialAdViewStatePresenting:
            return @"presenting";
        case CPInterstitialAdViewStateHidding:
            return @"hidding";
        case CPInterstitialAdViewStateHidden:
            return @"hidden";
    }
    
    return @"unknown";
}

@end
