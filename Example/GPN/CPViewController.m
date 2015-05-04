//
//  CPViewController.m
//  GPN
//
//  Created by Alex Lementuev on 04/30/2015.
//  Copyright (c) 2014 Alex Lementuev. All rights reserved.
//

#import "CPViewController.h"

#import <CrossPromotion.h>

@interface CPViewController () <CPInterstitialAdViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *presentButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation CPViewController

#pragma mark -
#pragma mark Actions

- (IBAction)onRequest:(id)sender
{
    [[CrossPromotion sharedInstance] startRequestingInterstitialsWithDelegate:self];
    
    [_activityIndicator startAnimating];
}

- (IBAction)onPresent:(id)sender
{
    CPInterstitialResult result = [[CrossPromotion sharedInstance] present];
    if (result != CPInterstitialResultPresented)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Interstitial ad can't be displayed now."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark -
#pragma mark Present button

- (void)setPresentButtonTitle:(NSString *)title
{
    [_presentButton setTitle:title forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark CPInterstitialAdViewDelegate

// Interstitial ad is received: it’s safe to present it now.
- (void)interstitialAdDidReceive:(CPInterstitialAdView *)adView
{
    NSLog(@"Interstitial ad received");
    
    [_activityIndicator stopAnimating];
    [self setPresentButtonTitle:@"Present now"];
}

//  Interstitial ad is failed to receive.
- (void)interstitialAdDidFail:(CPInterstitialAdView *)adView withError:(NSError *)error
{
    NSLog(@"Failed to receive interstitial ad: %@", [error localizedDescription]);
    
    [_activityIndicator stopAnimating];
    [self setPresentButtonTitle:@"Try present"];
}

// Interstitial ad will present full screen modal view.
- (void)interstitialAdWillOpen:(CPInterstitialAdView *)adView
{
    NSLog(@"Interstitial ad will open");
}

// Interstitial ad did present full screen modal view. You can pause your game here.
- (void)interstitialAdDidOpen:(CPInterstitialAdView *)adView
{
    NSLog(@"Interstitial ad did open");
    [self setPresentButtonTitle:@"Try present"];
}

// Interstitial ad will hide full screen modal view.
- (void)interstitialAdWillClose:(CPInterstitialAdView *)adView
{
    NSLog(@"Interstitial ad will close");
}

// Interstitial ad did hide full screen modal view. You can resume your game here.
- (void)interstitialAdDidClose:(CPInterstitialAdView *)adView;
{
    NSLog(@"Interstitial ad did close");
    [_activityIndicator startAnimating];
}

// Return YES if ad should be destroyed on a low memory warning.
- (BOOL)interstitialAdShouldDestroyOnLowMemory
{
    return YES;
}

// Interstitial ad was destroyed after receiving low memory warning.
- (void)interstitialAdLowMemoryDidDestroy
{
    NSLog(@"Interstitial ad is destroyed due to low memory warning");
}

@end
