//
//  CPDefines.h
//  CPDefines
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

#ifndef CPDefines_h__
#define CPDefines_h__

#if __has_feature(objc_arc)

    #ifndef __CP_BLOCKSAFE
    #define __CP_BLOCKSAFE __weak
    #endif

    #ifndef __CP_STRONG
    #define __CP_STRONG __strong
    #endif

    #ifndef __CP_BRIDGE_TRANSFER
    #define __CP_BRIDGE_TRANSFER __bridge_transfer
    #endif

    #ifndef __CP_BRIDGE
    #define __CP_BRIDGE __bridge
    #endif

#else // __has_feature(objc_arc)

    #ifndef __CP_BLOCKSAFE
    #define __CP_BLOCKSAFE __block
    #endif

    #ifndef __CP_STRONG
    #define __CP_STRONG
    #endif

    #ifndef __CP_BRIDGE_TRANSFER
    #define __CP_BRIDGE_TRANSFER
    #endif

    #ifndef __CP_BRIDGE
    #define __CP_BRIDGE
    #endif


#endif // __has_feature(objc_arc)

#if __has_feature(cxx_exceptions)

    #ifndef CPTRY
    #define CPTRY @try
    #endif

    #ifndef CPCATCH
    #define CPCATCH(x) @catch (NSException *x)
    #endif

    #ifndef CPFINALLY
    #define CPFINALLY @finally
    #endif

#else

    #ifndef CPTRY
    #define CPTRY
    #endif

    #ifndef CPCATCH
    #define CPCATCH(x) NSException *x = nil; if(0)
    #endif

    #ifndef CPFINALLY
    #define CPFINALLY if(0)
    #endif

#endif

#if __cplusplus
    #define CP_EXTERN_C_BEGIN extern "C" {
    #define CP_EXTERN_C_END              }
#else
    #define CP_EXTERN_C_BEGIN
    #define CP_EXTERN_C_END
#endif


#ifndef CP_OBSERVERS_ADD
#define CP_OBSERVERS_ADD(NAME, SELECTOR) [[NSNotificationCenter defaultCenter] addObserver:self selector:(SELECTOR) name:(NAME) object:nil]
#endif

#ifndef CP_OBSERVERS_REMOVE
#define CP_OBSERVERS_REMOVE(NAME) [[NSNotificationCenter defaultCenter] removeObserver:self name:(NAME) object:nil]
#endif

#ifndef CP_OBSERVERS_REMOVE_ALL
#define CP_OBSERVERS_REMOVE_ALL() [[NSNotificationCenter defaultCenter] removeObserver:self]
#endif

#ifndef CP_COMMON_H
#define CP_COMMON_H \
- (void)registerObserver:(NSString *)name selector:(SEL)selector; \
- (void)unregisterObserver:(NSString *)name; \
- (void)unregisterObservers;
#endif // CP_COMMON_H

#ifndef CP_COMMON_M
#define CP_COMMON_M \
- (void)registerObserver:(NSString *)name selector:(SEL)selector { CP_OBSERVERS_ADD(name, selector); } \
- (void)unregisterObserver:(NSString *)name { CP_OBSERVERS_REMOVE(name); } \
- (void)unregisterObservers { CP_OBSERVERS_REMOVE_ALL(); }
#endif // CP_COMMON_M

#endif // CPDefines_h__
