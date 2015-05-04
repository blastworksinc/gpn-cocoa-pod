//
//  CPDebug.h
//  CPDebug
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

#import "CPDefines.h"

typedef enum {
    CPLogLevelNone  = -1,
    CPLogLevelCrit  = 0,
    CPLogLevelError = 1,
    CPLogLevelWarn  = 2,
    CPLogLevelInfo  = 3,
    CPLogLevelDebug = 4
} CPLogLevel;

typedef NS_ENUM(NSInteger, CPLogTag) {
    CPTagMaskAll        = 0xffff,
    CPTagMaskNone       = 0,
    
    CPTagCommon     = 1,
    CPTagJavaScript = 2,
    CPTagCommands   = 3,
    CPTagNetwork    = 4,
    CPTagCallbacks  = 5,
    CPTagPurchase   = 6,
    CPTagSettings   = 7
};

CP_EXTERN_C_BEGIN

void CPLogSetDebugEnabled(BOOL flag);
void CPLogSetTagEnabled(CPLogTag tag, BOOL flag);
void CPLogSetTagMask(CPLogTag mask);

void CPLogSetLogLevel(CPLogLevel level);
void CPRemoteMonitorConnect(NSString *host, uint16_t port);

BOOL CPIsDebugEnabled(void);

void CPLogCrit(CPLogTag tag, NSString *format, ...);
void CPLogError(CPLogTag tag, NSString *format, ...);
void CPLogWarn(CPLogTag tag, NSString *format, ...);
void CPLogInfo(CPLogTag tag, NSString *format, ...);
void CPLogDebug(CPLogTag tag, NSString *format, ...);

void _CPAssert(const char* expression, const char* file, int line, const char* function);
void _CPAssertMsg(const char* expression, const char* file, int line, const char* function, NSString *message);
void _CPAssertMsgv(const char* expression, const char* file, int line, const char* function, NSString *format, ...);

void _CPDiagnosticMsg(NSString *format, ...);

void _CPDummyFunctionForEmptyDefines();

CP_EXTERN_C_END

#define CPAssert(expression) if (!(expression)) _CPAssert(#expression, __FILE__, __LINE__, __FUNCTION__)
#define CPAssertMsg(expression, msg) if (!(expression)) _CPAssertMsg(#expression, __FILE__, __LINE__, __FUNCTION__, (msg))
#define CPAssertMsgv(expression, msg, ...) if (!(expression)) _CPAssertMsgv(#expression, __FILE__, __LINE__, __FUNCTION__, (msg), __VA_ARGS__)

#define CPDiagnosticMsg(...) _CPDiagnosticMsg(__VA_ARGS__)
