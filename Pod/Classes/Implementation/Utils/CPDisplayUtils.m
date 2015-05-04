//
//  CPDisplayUtils.m
//  CPDisplayUtils
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

#import <QuartzCore/QuartzCore.h>

#import "CPDisplayUtils.h"

#import "CrossPromotion_Internal.h"

UIInterfaceOrientation CPGetInterfaceOrientation()
{
	return [UIApplication sharedApplication].statusBarOrientation;
}

BOOL CPIsInterfaceOrientationLandscape(void)
{
    return UIInterfaceOrientationIsLandscape(CPGetInterfaceOrientation());
}

BOOL CPIsInterfaceOrientationPortrait(void)
{
    return UIInterfaceOrientationIsPortrait(CPGetInterfaceOrientation());
}

UIWindow * CPGetKeyWindow()
{
    return [UIApplication sharedApplication].keyWindow;
}

CGFloat CPGetStatusBarHeight()
{
    if ([UIApplication sharedApplication].statusBarHidden) return 0.0;
    
    if (CPConfigNeedsTransformForViewInWindow)
    {
        UIInterfaceOrientation orientation = CPGetInterfaceOrientation();
    
        return UIInterfaceOrientationIsLandscape(orientation) ?
        CGRectGetWidth([UIApplication sharedApplication].statusBarFrame) :
        CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    }
    
    return CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
}

CGRect CPGetApplicationFrame()
{
    CGRect frame = CPGetScreenBounds();
    frame.origin.y += CPGetStatusBarHeight();
    frame.size.height -= CPGetStatusBarHeight();
    
    return frame;
}

CGRect CPGetScreenBounds()
{
	CGRect bounds = [UIScreen mainScreen].bounds;
	
	if (CPConfigNeedsTransformForViewInWindow && UIInterfaceOrientationIsLandscape(CPGetInterfaceOrientation()))
	{
		CGFloat width = bounds.size.width;
		bounds.size.width = bounds.size.height;
		bounds.size.height = width;
	}
	
	return bounds;
}

CGSize CPGetScreenSize()
{
    return CPGetScreenBounds().size;
}

NSString * CPGetScreenSizeStr()
{
    CGSize size = CPGetScreenSize();
    return [NSString stringWithFormat:@"%dx%d", (int)size.width, (int)size.height];
}

CGFloat CPGetDeviceScale()
{
    if ([UIScreen instancesRespondToSelector:@selector(scale)])
    {
        return [[UIScreen mainScreen] scale];
    }
    
    return 1.0;
}

UIImage *CPGetSnapshotImage(UIView *view)
{
    CGSize layerSize = view.bounds.size;
    if (CPGetDeviceScale() == 2.0f)
    {
        UIGraphicsBeginImageContextWithOptions(layerSize, NO, 2.0f);
    }
    else
    {
        UIGraphicsBeginImageContext(layerSize);
    }
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
}
