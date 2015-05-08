# GameHouse Promotion Network SDK for CocoaPods

[![CI Status](http://img.shields.io/travis/Alex Lementuev/GPN.svg?style=flat)](https://travis-ci.org/Alex Lementuev/GPN)
[![Version](https://img.shields.io/cocoapods/v/GPN.svg?style=flat)](http://cocoapods.org/pods/GPN)
[![License](https://img.shields.io/cocoapods/l/GPN.svg?style=flat)](http://cocoapods.org/pods/GPN)
[![Platform](https://img.shields.io/cocoapods/p/GPN.svg?style=flat)](http://cocoapods.org/pods/GPN)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

GPN is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "GPN"
```

The GameHouse Promotion Network lets you drive app installs with intelligence and control. You can participate in GPN by integrating this open source SDK into your iOS apps. Also available for Android.

## Simple Steps

1. Signup for the GameHouse Promotion Network at http://partners.gamehouse.com/gpn/.
2. Register your apps to obtain a GPN App ID for each.
3. Upload a few marketing assets to enable your app to be promoted in other GPN apps.
4. Integrate this SDK into your app to start showing ads for other GPN apps.

## Integration Instructions

1. Add "GPN" pod into your Podfile.

2. Initialize CrossPromotion singleton in your app delegate. **Make sure to include your App ID**:

        #import <CrossPromotion.h>
        ...
        - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
        {
            ...    
            [CrossPromotion initializeWithAppId:@"your_app_id"];            
            return YES;
        }

3. Adopt CPInterstitialAdViewDelegate protocol (typically in a subclass of UIViewController class):

        #import <CrossPromotion.h>
        
        @interface ViewController () <CPInterstitialAdViewDelegate>
        ...
        @end

        @implementation ViewController
        ...
        
        #pragma mark -
        #pragma mark CPInterstitialAdViewDelegate

        // Interstitial ad is received: it’s safe to present it now.
        - (void)interstitialAdDidReceive:(CPInterstitialAdView *)adView
        {
            NSLog(@"Interstitial ad received");
        }

        //  Interstitial ad is failed to receive.
        - (void)interstitialAdDidFail:(CPInterstitialAdView *)adView withError:(NSError *)error
        {
            NSLog(@"Failed to receive interstitial ad: %@", [error localizedDescription]);
        }
        
        // Interstitial ad will present full screen modal view.
        - (void)interstitialAdWillOpen:(CPInterstitialAdView *)adView
        {
            NSLog(@"Interstitial ad will open");
        }

        // Interstitial ad presented full screen modal view. You can pause your game here.
        - (void)interstitialAdDidOpen:(CPInterstitialAdView *)adView
        {
            NSLog(@"Interstitial ad did open");
        }
        
        // Interstitial ad will hide full screen modal view.
        - (void)interstitialAdWillClose:(CPInterstitialAdView *)adView
        {
            NSLog(@"Interstitial ad did close");
        }

        // Interstitial ad hided full screen modal view. You can resume your game here.
        - (void)interstitialAdDidClose:(CPInterstitialAdView *)adView
        {
            NSLog(@"Interstitial ad did close");
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
        ...
        @end

4.  Start requesting interstitial ads from the server:

        [[CrossPromotion sharedInstance] startRequestingInterstitialsWithDelegate:self]; // enclosing class should adopt CPInterstitialAdViewDelegate protocol
        
    **Note**: you should call startRequestingInterstitialsWithDelegate: only once. The interstitial rotation is handled automatically by the SDK. Each time a new interstitial is received the CPInterstitialAdViewDelegate’s interstitialAdDidReceive: is called. You only need to call startRequestingInterstitialsWithDelegate: if a network error occurres and interstitialAdDidFail:withError: is fired. The ad serving might stop if a low memory warning is received but in this case the SDK will resume serving ads automatically (when more memory becomes available). For more info check the "Low memory warning" section.

5.  Call the "present" method whenever it's appropriate to present an interstitial ad (e.g. during a level break). The ad will display only if it is fully preloaded. It’s safe to present an interstitial after the delegate’s “did receive” callback method is called:

        CPInterstitialResult result = [[CrossPromotion sharedInstance] present];
        if (result != CPInterstitialResultPresented)
        {
            CPDiagnosticMsg(@"Unable to present interstitial ad view");
        }
        
    Possible return values:

        CPInterstitialResultPresented: “present” call succeed: an interstitial ad will be presented fullscreen
        CPInterstitialResultNotPresented: “present” call did not result in showing an ad
        CPInterstitialResultNotPresentedForbidsPosition: interstitial "position" is disabled

## Trailer video landscape mode

If you want to play the video trailer in landscape mode for a portrait mode application:  

1. Enable landscape orientation in the application settings:  

        Check “Landscape Left” and “Landscape Right” button on the “Summary” tab of your app target settings.  
        -or-  
        Add “Landscape (left home button)” and “Landscape (right home button)” to the “Supported interface orientations” on the “Info” tab of your app target settings.  
        
2. Set your UIViewController(s) preferred orientation to portrait:

        #pragma mark -
        #pragma mark Interface Orientations
        
        // iOS 6.0+
        - (NSUInteger)supportedInterfaceOrientations
        {
            return UIInterfaceOrientationMaskPortrait;
        }
        
        // pre iOS 6.0
        -(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
        {
            if (orientation == UIInterfaceOrientationPortrait)
                return YES;
            
            return NO;
        }

## Ad Positions
If you want to define different ad behavior for different points in your game, you can include an optional params dictionary when calling "present" method to pass a "position" param. For example:
    
    NSDictionary *params = @{ "position" : "startup" };
    CPInterstitialResult result = [[CrossPromotion sharedInstance] presentWithParams:params];
    if (result != CPInterstitialResultPresented)
    {
        CPDiagnosticMsg(@"Unable to present interstitial ad view");
    }

Currently, we recognize only three position values:

* startup
* interstitial
* trial-end

Contact us if you want to define additional positions.

## Low memory warning
The GPN SDK listens for low memory warning notifications and stops serving ads to free as much memory as it can when a low memory situation occurs. You may affect the way it behaves by implementing CPInterstitialAdViewDelegate‘s optional method:

        - (BOOL)interstitialAdShouldDestroyOnLowMemory; 
        
You should do it at your own risk since the low memory amount can lead your app to a crash.
By default the ad serving stops and the optional CPInterstitialAdViewDelegate‘s method is called:

        - (void)interstitialAdLowMemoryDidDestroy;
        
**Note** The ad serving will resume automatically when more memory becomes available: you don't need to call the startRequestingInterstitialsWithDelegate: method.	

## Optional ads parameters
Each ads request can include a set of optional parameters. In order to add them you should implement CPInterstitialAdViewDelegate’s optional method:

        - (NSDictionary *)interstitialAdParams
        {
            return @{ <key1> : <value1>, <key2> : <value2>, ... };
        }

## Tracking In-App Purchases

GPN can observe in-app purchase activity to improve ad targeting (for example, showing fewer ads to users who have already generated revenue via in-app purchase, or showing more ads to users who are willing to spend money). Follow these steps to enable this:

1. Initialize GPN as described above. (Make sure you’ve done it before adding your SKPaymentTransactionObserver.)

2. Register your SKPaymentTransactionObserver:

        [[SKPaymentQueue defaultQueue] addTransactionObserver:observer];

3. Register your purchases with GPN:
    
        - (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
        {
            for (SKPaymentTransaction *transaction in transactions)
            {
                switch (transaction.transactionState)
                {
                    case SKPaymentTransactionStatePurchased:
                        [[CrossPromotion sharedInstance] queueTransaction:transaction];
                        ...
                        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                        break;
                    case SKPaymentTransactionStateFailed:
                        ...
                        break;
                }
            }
        }

## Author

GameHouse, gpn-support@realnetworks.com

## License

GPN is available under the Apache License, Version 2.0. See the LICENSE file for more info.
