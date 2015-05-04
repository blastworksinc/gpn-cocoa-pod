//
//  CPDebugUI.m
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

#import "CPDebugUI.h"
#import "CPCommon.h"

NSString * const CPDebugRequestState    = @"CPDebugRequestState";
NSString * const CPDebugAppConsole      = @"CPDebugAppConsole";

static CPDebugUI *sharedInstance;

@interface CPDebugUI ()
{
    NSMutableDictionary * _bindingsDict;
}

@end

@implementation CPDebugUI

- (id)init
{
    self = [super init];
    if (self)
    {
        _bindingsDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}


#pragma mark -
#pragma mark Binding

- (void)bindUIDelegate:(id)delegate forKey:(NSString *)key
{
    CPSafeSetObject(_bindingsDict, delegate, key);
}

- (void)setStateText:(NSString *)text forKey:(NSString *)key
{
    id obj = [_bindingsDict objectForKey:key];
    if ([obj respondsToSelector:@selector(setText:)])
    {
        [obj setText:text];
    }
}

- (void)appendConsoleText:(NSString *)text forKey:(NSString *)key
{
    id obj = [_bindingsDict objectForKey:key];
    if ([obj respondsToSelector:@selector(appendLine:)])
    {
        static NSDateFormatter *dateFormatter;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"HH:mm:ss.SSS"];
        });
        
        NSString *line = [NSString stringWithFormat:@"%@: %@", [dateFormatter stringFromDate:[NSDate date]], text];
        if ([NSThread isMainThread])
        {
            [obj appendLine:line];
        }
        else
        {
            [obj performSelectorOnMainThread:@selector(appendLine:) withObject:line waitUntilDone:NO];
        }
    }
}

#pragma mark -
#pragma mark Shared instance

+ (CPDebugUI *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

@end
