//
//  CPReachability.h
//  CPReachability
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

#import <Foundation/Foundation.h>

typedef enum
{
	CPNetworkStatusUnreachable = 0,
	CPNetworkStatusReachableWiFi,
    CPNetworkStatusReachableCarrier,
    CPNetworkStatusReachableUnknown,
} CPNetworkStatus;

// this is a weird Marmalade SDK bug:
// we can't use 'extern NSString * const' because
// when building under Windows, some of the constants turn
// to be nil. Defines work fine.

#define CPReachabilityDidChangeNotification @"CPReachabilityDidChangeNotification"

#define CPNetworkUnreachable                @"unreachable"
#define CPNetworkReachableWiFi              @"wi-fi"
#define CPNetworkReachableCarrier           @"carrier"
#define CPNetworkReachableUnknown           @"unknown"

@interface CPReachability : NSObject

// Starts listening for reachability notifications on the current run loop
+ (BOOL)startGeneratingNotifications;

// Stops listening for reachability notifications
+ (void)stopGeneratingNotificatons;

+ (CPNetworkStatus)currentReachabilityStatus;
+ (NSString *)currentReachabilityStatusString;

@end


