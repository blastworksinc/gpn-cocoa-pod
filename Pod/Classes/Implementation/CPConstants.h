//
//  CPConstants.h
//  CPConstants
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

#ifndef CP_CONSTANTS_H__
#define CP_CONSTANTS_H__

// this is a weird Marmalade SDK bug:
// we can't use 'extern NSString * const' because
// when building under Windows, some of the constants turn
// to be nil. Defines work fine.

#import <Foundation/Foundation.h>

// SDK configuration
#define kCPSDKVersion                           @"3.0.2"

// Server configuration
#define kCPServerDefaultURL                     @"http://gpn-api.gamehouse.com"

// request params
#define kCPRequestParamSDKVersion               @"sdk_version"

#define kCPRequestParamAppId                    @"app_id[gpn]"
#define kCPRequestBundleId                      @"app_id[bundle_id]"
#define kCPRequestAppVersionCode                @"app[version_code]"
#define kCPRequestAppVersionName                @"app[version_name]"

#define kCPRequestParamMacId                    @"device_id[mac_id]"
#define kCPRequestParamAdvertisingIdentifier    @"device_id[idfa]"
#define kCPRequestParamAdvertisingTracker       @"device_id[idfa_track]"

#define kCPRequestParamFacebookUserId           @"facebook[user_id]"

#define kCPRequestParamScreenWidth              @"screen_size[width]"
#define kCPRequestParamScreenHeight             @"screen_size[height]"

#define kCPRequestParamFreeMemory               @"system[free_memory]"

#define kCPRequestParamCarrier                  @"carrier"
#define kCPRequestParamConnectionType           @"connection_type"

#define kCPRequestParamCountry                  @"country"

#define kCPRequestParamSystemPlatform           @"system[platform]"
#define kCPRequestParamSystemDevice             @"system[device]"
#define kCPRequestParamSystemVersion            @"system[version]"

#define kCPRequestParamWrapperName              @"wrapper[name]"
#define kCPRequestParamWrapperVersion           @"wrapper[version]"

#define kCPRequestParamViewState                @"view[state]"

#define kCPRequestParamDebug                    @"debug_mode"

#endif // CP_CONSTANTS_H__
