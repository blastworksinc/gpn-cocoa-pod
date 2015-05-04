//
//  CPDebugUI.h
//  CPDebugUI
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

#import <UIKit/UIKit.h>

#ifdef CP_DEBUG_UI
    #import "CPStringUtils.h"

    #define CPDebugUIBind(key,obj)      [[CPDebugUI sharedInstance] bindUIDelegate:(obj) forKey:(key)]
    #define CPDebugSetStatus(key,...)   [[CPDebugUI sharedInstance] setStateText:CPStringFormat(__VA_ARGS__) forKey:(key)]
    #define CPDebugLogConsole(key,...)  [[CPDebugUI sharedInstance] appendConsoleText:CPStringFormat(__VA_ARGS__) forKey:(key)]
#else
    #define CPDebugUIBind(key,obj)
    #define CPDebugSetStatus(key,...)
    #define CPDebugLogConsole(key,...)
#endif // CP_DEBUG_UI

#define CPDebugSetRequestStatus(...)    CPDebugSetStatus(CPDebugRequestState, __VA_ARGS__)
#define CPDebugLog(...)                 CPDebugLogConsole(CPDebugAppConsole, __VA_ARGS__)

extern NSString * const CPDebugRequestState;
extern NSString * const CPDebugAppConsole;

@interface CPDebugUI : NSObject

- (void)bindUIDelegate:(id)delegate forKey:(NSString *)key;
- (void)setStateText:(NSString *)text forKey:(NSString *)key;
- (void)appendConsoleText:(NSString *)text forKey:(NSString *)key;

+ (CPDebugUI *)sharedInstance;

@end

////////////////////////////////////////////////////////////////////

@protocol CPDebugUIDelegate <NSObject>

- (void)setText:(NSString *)text;
- (void)appendLine:(NSString *)line;

@end
