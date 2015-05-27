//
//  CPDeviceUtils.h
//  CPDeviceUtils
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
#import <CoreTelephony/CTCarrier.h>

#import <mach/mach.h>
#import <mach/mach_host.h>

#define CP_B2MB(X) ((X) * 9.5367431640625e-07)
#define CP_MB2B(X) ((X) * 1048576)

typedef enum {
    CPAdvertisingTrackingStateUnknown  = -1,
    CPAdvertisingTrackingStateDisabled =  0,
    CPAdvertisingTrackingStateEnabled  =  1
} CPAdvertisingTrackingState;

typedef struct {
    natural_t free;
    natural_t used;
    natural_t total;
} CPMemoryUsageInfo;

// unique identifier
NSString * CPGetMacAddressIdentifier(void);
NSString * CPCreateUniqueAdvertisingIdentifier(void);
NSString * CPGetFacebookAppUserId(void);

CPAdvertisingTrackingState CPGetUniqueAdvertisingIdentifierTrackerState(void);

// locale
NSString * CPGetLocaleCountry(void);

// carrier
CTCarrier * CPGetCarrierInfo(void);

natural_t CPGetUsedMemory(void);
natural_t CPGetFreeMemory(void);

BOOL CPGetMemoryUsageInfo(CPMemoryUsageInfo* info);

NSString *CPGetDeviceMachine(void);
