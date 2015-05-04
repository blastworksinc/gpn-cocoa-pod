//
//  CPSettings.m
//  CPSettings
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

#import "CPSettings.h"

#import "CPCommon.h"

#define CPSettingsDataFile @"com.gamehouse.crosspromotion.Settings.bin"

#define CPSettingsKeyPurchaseSettings @"iap"
#define CPSettingsKeyInstallTrackingSettings @"install_tracking"
#define CPSettingsKeyLowMemory @"low_memory"

#define CPSettingsRequestErrorDomain @"CPSettingsRequestErrorDomain"

@implementation CPSettings

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _install_tracking = [CPInstallTrackingSettings new];
        
        [self loadFromExistingDictionary];
    }
    return self;
}

- (void)saveExistingDictionary:(NSDictionary *)dictionary
{
    NSString* path = CPGetAppSupportDirectorySubpath(CPSettingsDataFile, YES);
    [dictionary writeToFile:path atomically:YES];
}

- (BOOL)loadFromExistingDictionary
{
    NSString* path = CPGetAppSupportDirectorySubpath(CPSettingsDataFile, NO);
    NSDictionary *existingDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    if (existingDictionary != nil)
    {
        [self loadFromDictionary:existingDictionary];
        return YES;
    }
    
    return NO;
}

- (void)loadFromDictionary:(NSDictionary *)dictionary
{
    id iapJson = [dictionary objectForKey:CPSettingsKeyPurchaseSettings];
    if ([iapJson isKindOfClass:[NSDictionary class]])
    {
        _iap = [[CPPurchaseTrackerSettings alloc] initWithDictionary:iapJson];
    }
    
    id installJson = [dictionary objectForKey:CPSettingsKeyInstallTrackingSettings];
    if ([installJson isKindOfClass:[NSDictionary class]])
    {
        _install_tracking = [[CPInstallTrackingSettings alloc] initWithDictionary:installJson];
    }
    
    id lowMemoryJson = [dictionary objectForKey:CPSettingsKeyLowMemory];
    if ([lowMemoryJson isKindOfClass:[NSDictionary class]])
    {
        _low_memory = [[CPLowMemorySettings alloc] initWithDictionary:lowMemoryJson];
    }
}

#pragma mark -
#pragma mark URL loading

- (void)loadWithRequest:(NSURLRequest *)request completion:(void(^)(CPSettings *settings, NSError *error))completion
{
    CPAssert(request);
    
    [[CrossPromotion sharedInstance].requestManager queueRequest:[CPHttpJSonRequest requestWithURLRequest:request]
                                                      completion:^(CPHttpRequest *request, NSError *error, BOOL cancelled)
    {
        if (cancelled)
        {
            return;
        }
        
        if (!error)
        {
            id obj = ((CPHttpJSonRequest *)request).responseJson;
            if ([obj isKindOfClass:[NSDictionary class]])
            {
                [self loadFromDictionary:obj];
                [self saveExistingDictionary:obj];
            }
        }
        
        if (completion)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(self, error);
            });
        }
    }];
}

#pragma mark -
#pragma mark Properties

- (void)setLow_memory:(CPLowMemorySettings *)low_memory
{
    _low_memory = low_memory;
}

@end
