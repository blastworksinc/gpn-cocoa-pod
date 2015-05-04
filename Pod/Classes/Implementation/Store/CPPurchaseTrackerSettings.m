//
//  CPPurchaseTrackerSettings.m
//  CPPurchaseTrackerSettings
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

#import "CPPurchaseTrackerSettings.h"

#import "CPCommon.h"
#import "CPPurchaseTrackerConstants.h"

#define kSecondsInADay (24 * 3600)

const NSInteger      CPPurchaseTrackerDefaultCacheSize  = 10;
const NSTimeInterval CPPurchaseTrackerDefaultCacheAge   = 30;
const NSTimeInterval CPPurchaseTrackerDefaultProductsRequestDelay = 5.0f;

@implementation CPPurchaseTrackerSettings

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _cache_age_days = CPPurchaseTrackerDefaultCacheAge;
        _cache_size = CPPurchaseTrackerDefaultCacheSize;
        _products_delay_secs = CPPurchaseTrackerDefaultProductsRequestDelay;
    }
    return self;
}

- (BOOL)checkValues
{
    _cache_age_seconds = kSecondsInADay * _cache_age_days;
    return _tracking_pixel_url != nil;
}

@end
