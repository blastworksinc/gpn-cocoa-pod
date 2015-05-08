//
//  CPGpnDisplayController.m
//  CPGpnDisplayController
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

#import "CPGpnDisplayController.h"

#import "CPUtils.h"

#import "CPGpnView_Controllers.h"
#import "CPGpnProperty.h"

#import "CrossPromotion_Internal.h"

@interface CPGpnDisplayController ()
{
    UIView * _contentView;
    BOOL     _statusBarShouldBeHidden;
    BOOL     _forcedClose;
}

@property (nonatomic, readwrite, strong) UIView * contentView;

@end

@implementation CPGpnDisplayController

@synthesize contentView = _contentView;

- (id)initWithAdView:(CPGpnView *)adView
{
    self = [super initWithAdView:adView];
    if (self)
    {
        [self initStatusBarState];
        [self initContentView];
        [self registerMoviePlayerNotifications];
        [self registerDeviceOrientationNotifications];
    }
    return self;
}

- (void)dealloc
{
    [self unregisterNotifications];
    
    [self.contentView removeFromSuperview];
    
}

#pragma mark -
#pragma mark Nofication observers

- (void)registerMoviePlayerNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerDidEnterFullscreen:)
                                                 name:@"UIMoviePlayerControllerDidEnterFullscreenNotification"
                                               object:nil];
    
    // Apparently Apple had this notification misspelled in iOS < 4.3
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerDidEnterFullscreen:)
                                                 name:@"UIMoviePlayerControllerDidEnterFullcreenNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerWillExitFullscreen:)
                                                 name:@"UIMoviePlayerControllerWillExitFullscreenNotification"
                                               object:nil];
    
    // Apparently Apple had this notification misspelled in iOS < 4.3
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerWillExitFullscreen:)
                                                 name:@"UIMoviePlayerControllerWillExitFullcreenNotification"
                                               object:nil];
}

- (void)registerDeviceOrientationNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarOrientationDidChangeNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

- (void)unregisterNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark MPMoviePlayer notifications

- (void)moviePlayerDidEnterFullscreen:(NSNotification *)notification
{
    [self hideExpandedElementsIfNeeded];
}

- (void)moviePlayerWillExitFullscreen:(NSNotification *)notification
{
    [self unhideExpandedElementsIfNeeded];
    
    if (_statusBarShouldBeHidden) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    [self rotateContentToOrientation:CPGetInterfaceOrientation()];
}

#pragma mark -
#pragma mark Device orientation notification

- (void)statusBarOrientationDidChangeNotification:(NSNotification *)notification
{
    UIInterfaceOrientation orientation = CPGetInterfaceOrientation();
    [self rotateToOrientation:orientation];
}

#pragma mark -
#pragma mark JavaScript

- (void)initializeJavascriptState
{
    NSArray *properties = [NSArray arrayWithObjects:
                           [CPGpnScreenSizeProperty propertyWithSize:CPGetApplicationFrame().size],
                           [CPGpnStateProperty propertyWithState:CPGpnViewStateHidden],
                           nil];
    
    [self.adView fireChangeEventsForProperties:properties];
}

#pragma mark -
#pragma mark Present

- (void)present
{
    _forcedClose = NO;
    
    [self makeUIChanges];
    
    [self animateShowing];
    
    [self.adView fireChangeEventForProperty:[CPGpnStateProperty propertyWithState:CPGpnViewStatePresented]];
}

- (void)initContentView
{
    _contentView = [[UIView alloc] initWithFrame:CPGetApplicationFrame()];
    _contentView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.75];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)makeUIChanges
{
    self.adView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    [_contentView addSubview:self.adView];
    [CPGetKeyWindow() addSubview:_contentView];
    
    // TODO: refactoring
    [self applyTransformForOrientation:CPGetInterfaceOrientation() toView:_contentView];
}

- (void)initStatusBarState
{
    _statusBarShouldBeHidden = [UIApplication sharedApplication].statusBarHidden;
}

#pragma mark -
#pragma mark Interface rotation

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
    [self.adView fireChangeEventForProperty:[CPGpnScreenSizeProperty propertyWithSize:CPGetApplicationFrame().size]];
    [self rotateContentToOrientation:newOrientation];
}

- (void)rotateContentToOrientation:(UIInterfaceOrientation)orientation
{
    [self applyTransformForOrientation:orientation toView:_contentView];
}

- (void)applyTransformForOrientation:(UIInterfaceOrientation)orientation toView:(UIView *)view
{
    if (CPConfigNeedsTransformForViewInWindow)
    {
        // We need to rotate the ad view in the direction opposite that of the device's rotation.
        // For example, if the device is in LandscapeLeft (90 deg. clockwise), we have to rotate
        // the view -90 deg. counterclockwise.
        CGFloat angle = 0.0;
        
        switch (orientation)
        {
            case UIInterfaceOrientationPortraitUpsideDown: angle = M_PI; break;
            case UIInterfaceOrientationLandscapeLeft: angle = -M_PI_2; break;
            case UIInterfaceOrientationLandscapeRight: angle = M_PI_2; break;
            default: break;
        }
        
        view.transform = CGAffineTransformMakeRotation(angle);
    }
    
    // frame
    CGRect frame = [UIScreen mainScreen].bounds;
    int statusBarHeight = CPGetStatusBarHeight();
    if (statusBarHeight > 0 && !_statusBarShouldBeHidden)
    {
        switch (orientation)
        {
            case UIInterfaceOrientationPortrait:
                frame.origin.y += statusBarHeight;
                frame.size.height -= statusBarHeight;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                frame.size.height -= statusBarHeight;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                frame.origin.x += statusBarHeight;
                frame.size.width -= statusBarHeight;
                break;
            case UIInterfaceOrientationLandscapeRight:
                frame.size.width -= statusBarHeight;
                break;
            default:
                break;
        }
    }
    
    view.frame = frame;
}

#pragma mark -
#pragma mark Close

- (void)close
{
    [self.adView adWillDismissModalView];
    [self animateHiding];
    
    [self.adView hide];
}

- (void)closeDelayed
{
    [self performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:NO];
}

- (void)forceClose
{
    [self forceCloseCallWillDismiss:YES callDidDismissClose:YES];
}

- (void)forceCloseCallWillDismiss:(BOOL)callWillClose callDidDismissClose:(BOOL)callDidClose
{
    CPAssert(!_forcedClose);
    _forcedClose = YES;
    
    if (self.adView.isModalShowing)
    {
        if (callWillClose)
        {
            [self.adView adWillDismissModalView];
        }
        
        [self.adView removeFromSuperview];
        [_contentView removeFromSuperview];
        
        if (callDidClose)
        {
            [self.adView adDidDismissModalView];
        }

        // for unit testing only
        [self onForceClose];
    }
}

- (void)onForceClose
{
    
}

#pragma mark -
#pragma mark Animation

- (void)animateShowing
{
    _contentView.alpha = 0.0;
    
    if (CPIsInterfaceOrientationLandscape() && CPConfigNeedsTransformForViewInWindow)
    {
        self.adView.center = CGPointMake(0.5 * CGRectGetHeight(_contentView.frame),
                                         CGRectGetWidth(CPGetApplicationFrame()) + 0.5 * CGRectGetHeight(self.adView.frame));
    }
    else
    {
        self.adView.center = CGPointMake(0.5 * CGRectGetWidth(_contentView.frame),
                                         CGRectGetHeight(CPGetApplicationFrame()) + 0.5 * CGRectGetHeight(self.adView.frame));
    }
    
    [UIView animateWithDuration:0.4 animations:^{
        // retain self in order not to crash on callback
        self.adView.frame = _contentView.bounds;
        _contentView.alpha = 1.0;
    }
    completion:^(BOOL finished) {
        [self showingAnimationDidStop];
    }];
}

- (void)animateHiding
{
    [UIView animateWithDuration:0.4 animations:^{
        // retain self in order not to crash on callback
        if (CPIsInterfaceOrientationLandscape() && CPConfigNeedsTransformForViewInWindow)
        {
            self.adView.center = CGPointMake(0.5 * CGRectGetHeight(_contentView.frame),
                                             CGRectGetWidth(CPGetApplicationFrame()) + 0.5 * CGRectGetHeight(self.adView.frame));
        }
        else
        {
            self.adView.center = CGPointMake(0.5 * CGRectGetWidth(_contentView.frame),
                                             CGRectGetHeight(CPGetApplicationFrame()) + 0.5 * CGRectGetHeight(self.adView.frame));
        }
        
        _contentView.alpha = 0.0;
    }
    completion:^(BOOL finished) {
        [self hiddingAnimationDidStop];
    }];
}

- (void)showingAnimationDidStop
{
    if (!_forcedClose)
    {
        [self.adView adDidPresentModalView];
    }
}

- (void)hiddingAnimationDidStop
{
    if (!_forcedClose)
    {
        [self.adView adDidDismissModalView];
        [self.adView removeFromSuperview];
        [_contentView removeFromSuperview];
    }
}

#pragma mark -
#pragma mark Modal views

- (void)hideExpandedElementsIfNeeded
{
    _contentView.hidden = YES;
}

- (void)unhideExpandedElementsIfNeeded
{
    _contentView.hidden = NO;
}

@end
