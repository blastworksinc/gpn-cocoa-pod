//
//  CPInstallTracking.m
//  CPInstallTracking
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

#import "CPInstallTracking.h"

#import "CPCommon.h"

#define kCPInstallTrackingFlagKey @"com.gamehouse.crosspromotion.InstallationTrackedFlag"

@implementation CPInstallTracking

+ (BOOL)isTracked
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kCPInstallTrackingFlagKey];
}

+ (void)clearTracked
{
    [self setTrackedFlag:NO];
}

+ (void)setTracked
{
    [self setTrackedFlag:YES];
}

+ (void)setTrackedFlag:(BOOL)flag
{
    [[NSUserDefaults standardUserDefaults] setBool:flag forKey:kCPInstallTrackingFlagKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)sendInstallTrackingRequestWithURL:(NSURL *)trackingURL andAppId:(NSString *)appId
{
    NSString *baseURLStr = [CrossPromotion sharedInstance].baseURL;
    if (!baseURLStr)
    {
        CPLogCrit(CPTagCommon, @"Can't send installation tracking URL: base URL is nil");
        return;
    }
    
    NSDictionary *params = @{
        @"type"   : @"sdk_install",
        @"origin" : [NSString stringWithFormat:@"%@#%d", baseURLStr, arc4random()]
    };
    NSURLRequest *request = [[CrossPromotion sharedInstance].serverApi createInstallTrackingRequestWithAppId:appId
                                                                                                 trackingURL:trackingURL
                                                                                                   andParams:params];
    
    CPHttpRequestManager *manager = [CrossPromotion sharedInstance].requestManager;
    [manager queueRequest:[CPHttpRequest requestWithURLRequest:request]
               completion:^(CPHttpRequest *request, NSError *error, BOOL cancelled) {
                   if (error) {
                       CPLogWarn(CPTagCommands, @"Unable to complete installation tracking request: %@", [error localizedDescription]);
                   } else if (cancelled) {
                       // do nothing
                   } else {
                       CPLogInfo(CPTagCommon, @"Install tracking succeed!");
                       
                       [self setTracked];
                   }
    }];
}

@end

@implementation CPInstallTrackingSettings

- (BOOL)checkValues
{
    return _tracking_pixel_url != nil;
}

@end
