//
//  CPStoreProductController.m
//  CPStoreProductController
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

#import <StoreKit/StoreKit.h>

#import "CPStoreProductController.h"
#import "CPCommon.h"

// weird bug: sometimes the SDK crashes the app when you try to show the SKStoreProductViewController in landscape mode. Not
// sure what's causing it, but this workaround works

@interface SKStoreProductViewController (CPFixInterfaceRotation)

@end

@implementation SKStoreProductViewController (CPFixInterfaceRotation)

- (BOOL)shouldAutorotate
{
    return [self.presentingViewController shouldAutorotate];
}

- (NSInteger)supportedInterfaceOrientations
{
    return [self.presentingViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [self.presentingViewController preferredInterfaceOrientationForPresentation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [self.presentingViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

@end

static CPStoreProductController * currentInstance;

@interface CPGpnCommand (StoreController)

- (void)finish;
- (void)finishWithError:(NSError *)error;

@end

@interface CPStoreProductController () <SKStoreProductViewControllerDelegate> {
    SKStoreProductViewController        * _productController;
    UIWindow                            * _window;
}

@property (nonatomic, strong) UIWindow * window;
@property (nonatomic, strong) SKStoreProductViewController * productController;

@end

@implementation CPStoreProductController

@synthesize window            = _window;
@synthesize productController = _productController;
@synthesize delegate          = _delegate;

#pragma mark -
#pragma mark Present

- (void)dealloc
{
    [self hideWindow];
    
    self.productController = nil;
}

#pragma mark -
#pragma mark SKStoreProductViewController

- (void)presentWithAppId:(NSString *)appId
{
    SKStoreProductViewController *productController = [[SKStoreProductViewController alloc] init];
    productController.delegate = self;
    NSDictionary *params = @{ SKStoreProductParameterITunesItemIdentifier : appId };
    [productController loadProductWithParameters:params completionBlock:^(BOOL result, NSError *error)
    {
        if (result)
        {
            /* We need to present store product controller on top of everything. Using
               one of the applicaiton's controllers doesnt work. So we create a separate
               window and use it's root controller for presenting
             */
            
            UIWindow * window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            UIViewController *controller = [[UIViewController alloc] init];
            controller.view.frame = window.bounds;
            controller.view.opaque = YES;
            controller.view.backgroundColor = [UIColor clearColor];
            controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            if (CPConfigOverrideWindowLevel)
            {
                int windowLevel = [UIApplication sharedApplication].keyWindow.windowLevel;
                window.windowLevel = windowLevel + 1;
            }
            
            window.rootViewController = controller;
            window.hidden = NO;
            self.window = window;
            
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [controller presentModalViewController:productController animated:YES]; // we should present modal view controller only when the window's controller is fully presented
            });
            
            #pragma clang diagnostic pop
            
            [self retainInstance];
        } else {
            [self notifyDidFailError:error];
        }
    }];
    self.productController = productController;
}

- (void)setProductController:(SKStoreProductViewController *)productController
{
    if (_productController != productController)
    {
        _productController.delegate = nil;
        _productController = productController;
    }
}

#pragma mark -
#pragma mark Delegate notifications

- (void)notifyDidFinish
{
    if ([_delegate respondsToSelector:@selector(productControllerDidFinish:)]) {
        [_delegate productControllerDidFinish:self];
    }
}

- (void)notifyDidFailError:(NSError *)error
{
    if ([_delegate respondsToSelector:@selector(productController:didFailError:)]) {
        [_delegate productController:self didFailError:error];
    }
}

#pragma mark -
#pragma mark SKStoreProductViewControllerDelegate

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:^{
        self.productController = nil; // break retain cycle
        [self notifyDidFinish];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self releaseInstance]; // should release window after the controller is fully dismissed
        });
    }];
}

#pragma mark -
#pragma mark Window

- (void)hideWindow
{
    _window.hidden = YES;
    self.window = nil;
}

#pragma mark -
#pragma mark Instance

/* 
 Not the greatest solution but works for now:
 We need to keed a reference to a SKStoreProductViewControllerDelegate in order to
 dissmiss product controller once it's done.
 We can't just retain 'self' because it won't work for ARC
 */

- (void)retainInstance
{
    CPAssert(currentInstance == nil);
    currentInstance = self;
}

- (void)releaseInstance
{
    CPAssert(currentInstance != nil);
    currentInstance = nil;
}

@end
