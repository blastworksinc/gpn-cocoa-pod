//
//  CPAvailability.h
//  CPAvailability
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

#ifndef CPAvailability_h__
#define CPAvailability_h__

#import <UIKit/UIKit.h>

#ifndef __IPHONE_5_0
#define __IPHONE_5_0     50000
#endif

#ifndef __IPHONE_6_0
#define __IPHONE_6_0     60000
#endif

#ifndef __IPHONE_7_0
#define __IPHONE_7_0     70000
#endif

#ifndef __IPHONE_8_0
#define __IPHONE_8_0     80000
#endif


#define CP_SYSTEM_VERSION_MIN __IPHONE_5_0

#define CP_IOS_SDK_AVAILABLE(sdk_ver) (__IPHONE_OS_VERSION_MAX_ALLOWED >= (sdk_ver))
#define CP_SYSTEM_VERSION_AVAILABLE(sys_ver) CPAvailabilitySystemVersionAvailable(sys_ver)
#define CP_SELECTOR_AVAILABLE(obj, sel) [(obj) respondsToSelector:@selector(sel)]
#define CP_CLASS_AVAILABLE(className) (NSClassFromString(@#className) != nil)

typedef NSUInteger CPSystemVersion;

void CPAvailabilityDetectSystemVersion(void);
BOOL CPAvailabilitySystemVersionAvailable(CPSystemVersion version);

#endif
