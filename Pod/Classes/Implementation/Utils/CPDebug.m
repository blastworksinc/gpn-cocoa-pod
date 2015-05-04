//
//  CPDebug.m
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

#import <UIKit/UIKit.h>

#import "CPDebug.h"
#import "CPCommon.h"
#import "BCRemoteMonitor.h"

#define kButtonTitleContinue    @"Continue"
#define kButtonTitleAbort       @"Abort"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static BOOL g_BlockingAlertActive;

@interface CPAlertViewDelegate : NSObject<UIActionSheetDelegate>
{
	NSString* alertMessage;
}

- (id)initWithExpression:(NSString *)expression
              andMessage:(NSString *)message
                  inFile:(NSString *)file
                 andLine:(NSInteger)line
              inFunction:(NSString *)function;
- (void)show;

@end

@implementation CPAlertViewDelegate

- (void)actionSheet:(UIActionSheet*)view didDismissWithButtonIndex:(NSInteger) buttonIndex
{
    NSString *buttonTitle = [view buttonTitleAtIndex:buttonIndex];
    NSLog(@"Assertion notification: '%@'", buttonTitle);
    if ([buttonTitle isEqualToString:kButtonTitleAbort])
    {
        abort();
    }
    
    g_BlockingAlertActive = NO;
}

- (void) actionSheetCancel:(UIActionSheet*)view
{
    g_BlockingAlertActive = NO;
}

- (id)initWithExpression:(NSString *)expression
              andMessage:(NSString *)message
                  inFile:(NSString *)file
                 andLine:(NSInteger)line
              inFunction:(NSString *)function
{
    self = [super init];
    if (self)
    {
        alertMessage = [[NSString alloc] initWithFormat:@"Assertion: (%@)\n with message: %@\n fails in:%@\nin file: %@:%d", expression, message, function, file, line];
    }
	return self;
}


- (void) show
{
	UIActionSheet* view = [[UIActionSheet alloc] initWithTitle:alertMessage
                                                      delegate:self
											 cancelButtonTitle:nil
                                        destructiveButtonTitle:kButtonTitleAbort
                                             otherButtonTitles:nil];
    [view addButtonWithTitle:kButtonTitleContinue];
	UIView* parentView = [UIApplication sharedApplication].keyWindow;
	[view showInView:parentView];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////

static CPLogLevel g_logLevel    = CPLogLevelInfo;
static BOOL g_DebugEnabled      = NO;
static CPLogTag g_tagMask       = (1 << CPTagCommon) | (1 << CPTagCallbacks);

static BOOL shouldLog(CPLogLevel level, CPLogTag tag);

static NSString* threadName(void);
static void logMessage(NSString *message);
static void sendRemoteLog(CPLogLevel level, NSString *thread, NSString *message);

#pragma mark -
#pragma mark Logger

void CPLogSetDebugEnabled(BOOL flag)
{
    g_DebugEnabled = flag;
    if (flag)
    {
        CPLogSetTagMask(CPTagMaskAll);
        CPLogSetLogLevel(CPLogLevelDebug);
    }
}

void CPLogSetTagEnabled(CPLogTag tag, BOOL flag)
{
    if (flag)
    {
        g_tagMask |= 1 << tag;
    }
    else
    {
        g_tagMask &= ~(1 << tag);
    }
}

void CPLogSetTagMask(CPLogTag mask)
{
    g_tagMask = mask;
}

void CPRemoteMonitorConnect(NSString *host, uint16_t port)
{
    [BCRemoteMonitor connectToHost:host port:port];
}

void CPLogSetLogLevel(CPLogLevel level)
{
    g_logLevel = level;
}

BOOL CPIsDebugEnabled(void)
{
    return g_DebugEnabled;
}

void CPLogCrit(CPLogTag tag, NSString *format, ...)
{
    if (shouldLog(CPLogLevelCrit, tag))
    {
        va_list ap;
        va_start(ap, format);
        
        NSString *thread = threadName();
        NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
        
        va_end(ap);
        
        sendRemoteLog(CPLogLevelCrit, thread, message);
        
        NSString *messageLong = thread != nil ?
            [[NSString alloc] initWithFormat:@"CP%@/C: %@", thread, message] :
            [[NSString alloc] initWithFormat:@"CP/C: %@", message];
        logMessage(messageLong);
        
    }
}

void CPLogError(CPLogTag tag, NSString *format, ...)
{
    if (shouldLog(CPLogLevelError, tag))
    {
        va_list ap;
        va_start(ap, format);
        
        NSString *thread = threadName();
        NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
        
        va_end(ap);
        
        sendRemoteLog(CPLogLevelError, thread, message);
        
        NSString *messageLong = thread != nil ?
            [[NSString alloc] initWithFormat:@"CP%@/E: %@", thread, message] :
            [[NSString alloc] initWithFormat:@"CP/E: %@", message];
        logMessage(messageLong);
        
    }
}

void CPLogWarn(CPLogTag tag, NSString *format, ...)
{
    if (shouldLog(CPLogLevelWarn, tag))
    {
        va_list ap;
        va_start(ap, format);
        
        NSString *thread = threadName();
        NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
        
        va_end(ap);
        
        sendRemoteLog(CPLogLevelWarn, thread, message);
        
        NSString *messageLong = thread != nil ?
            [[NSString alloc] initWithFormat:@"CP%@/W: %@", thread, message] :
            [[NSString alloc] initWithFormat:@"CP/W: %@", message];
        logMessage(messageLong);
        
    }
}

void CPLogInfo(CPLogTag tag, NSString *format, ...)
{
    if (shouldLog(CPLogLevelInfo, tag))
    {
        va_list ap;
        va_start(ap, format);
        
        NSString *thread = threadName();
        NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
        
        va_end(ap);
        
        sendRemoteLog(CPLogLevelInfo, thread, message);
        
        NSString *messageLong = thread != nil ?
            [[NSString alloc] initWithFormat:@"CP%@/I: %@", thread, message] :
            [[NSString alloc] initWithFormat:@"CP/I: %@", message];
        
        logMessage(messageLong);
        
    }
}

void CPLogDebug(CPLogTag tag, NSString *format, ...)
{
    if (shouldLog(CPLogLevelDebug, tag))
    {
        va_list ap;
        va_start(ap, format);
        
        NSString *thread = threadName();
        NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
        
        va_end(ap);
        
        sendRemoteLog(CPLogLevelDebug, thread, message);
        
        NSString *messageLong = thread != nil ?
            [[NSString alloc] initWithFormat:@"CP%@/D: %@", thread, message] :
            [[NSString alloc] initWithFormat:@"CP/D: %@", message];
        logMessage(messageLong);
        
    }
}

static NSString* threadName()
{
    if ([NSThread currentThread].isMainThread)
    {
        return nil;
    }
    
    NSString *threadName = [NSThread currentThread].name;
    if (threadName.length > 0)
    {
        return [NSString stringWithFormat:@"%@", threadName];
    }
    
    if (g_DebugEnabled && dispatch_get_current_queue)
    {
        dispatch_queue_t currentQueue = dispatch_get_current_queue();
        if (currentQueue != NULL)
        {
            if (currentQueue == dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
            {
                return @"QUEUE_DEFAULT";
            }
            if (currentQueue == dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0))
            {
                return @"QUEUE_HIGH";
            }
            if (currentQueue == dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0))
            {
                return @"QUEUE_LOW";
            }
            if (currentQueue == dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
            {
                return @"QUEUE_BACKGROUND";
            }
            
            const char *label = dispatch_queue_get_label(currentQueue);
            return label != NULL ? [NSString stringWithFormat:@"%s", label] : @"Serial queue";
        }
    }
    
    return @"Background Thread";
}

static BOOL shouldLog(CPLogLevel level, CPLogTag tag)
{
    return level <= g_logLevel && (g_tagMask & (1 << tag));
}

static void logMessage(NSString *message)
{
    NSLog(@"%@", message);
    CPDebugLog(message);
}

static void sendRemoteLog(CPLogLevel level, NSString *thread, NSString *message)
{
    if ([BCRemoteMonitor isConnected])
    {
        [BCRemoteMonitor sendLogLevel:level thread:(thread != nil ? thread : @"main") message:message];
    }
}

#pragma mark -
#pragma mark Assertions

static void displayBlockingAlert(NSString *expression, NSString *message, NSString *file, NSInteger line, NSString *function);
static const char * shortenFilePath(const char * path);

void _CPAssert(const char* expression, const char* file, int line, const char* function)
{
    _CPAssertMsg(expression, file, line, function, @"");
}

void _CPAssertMsg(const char* expression, const char* file, int line, const char* function, NSString *message)
{
    _CPAssertMsgv(expression, file, line, function, message);
}

void _CPAssertMsgv(const char* expressionCStr, const char* fileCStr, int line, const char* functionCStr, NSString *format, ...)
{
    fileCStr = shortenFilePath(fileCStr);
    
    va_list ap;
    va_start(ap, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
    NSString *consoleMessage = [[NSString alloc] initWithFormat:@"CP/ASSERT: (%s) in %s:%d %s message:'%@'",
                                expressionCStr, fileCStr, line, functionCStr, message];
    NSLog(@"%@", consoleMessage);
    va_end(ap);

    if (g_DebugEnabled)
    {
        NSString *expression = [NSString stringWithUTF8String:expressionCStr];
        NSString *file       = [NSString stringWithUTF8String:fileCStr];
        NSString *function   = [NSString stringWithUTF8String:functionCStr];
        if ([NSThread isMainThread])
        {
            displayBlockingAlert(expression, message, file, line, function);
        }
        else
        {
            dispatch_sync(dispatch_get_main_queue(), ^{
                displayBlockingAlert(expression, message, file, line, function);
            });
        }
    }
    
}

void _CPDiagnosticMsg(NSString *format, ...)
{
    va_list ap;
    va_start(ap, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Debug" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    });
    va_end(ap);
}

void _CPDummyFunctionForEmptyDefines() {}

static void displayBlockingAlert(NSString *expression, NSString *message, NSString *file, NSInteger line, NSString *function)
{
    CPAlertViewDelegate* alertDelegate = [[CPAlertViewDelegate alloc] initWithExpression:expression
                                                                          andMessage:message
                                                                              inFile:file
                                                                             andLine:line
                                                                          inFunction:function];
    [alertDelegate show];
    
    g_BlockingAlertActive = TRUE;
	while (g_BlockingAlertActive)
	{
		while(CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, TRUE) == kCFRunLoopRunHandledSource);
	}
}

static const char * shortenFilePath(const char * path)
{
	const char *to_return = path;
	const char *p = path; while (*p) ++p;
	while (p >= path)
	{
		--p;
		if (*p == '/')
        {
			to_return = p+1;
            break;
        }
	}
	
	return to_return;
}

#pragma clang diagnostic pop