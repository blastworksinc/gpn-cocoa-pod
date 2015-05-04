//
//  CPLowMemorySettings.m
//  CPLowMemorySettings
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

#import "CPLowMemorySettings.h"

@implementation CPLowMemorySettings

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _threshold = 30;
        _timeout_secs = 30;
    }
    return self;
}

@end
