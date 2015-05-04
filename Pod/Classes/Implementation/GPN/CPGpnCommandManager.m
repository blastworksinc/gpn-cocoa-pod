//
//  CPGpnCommandManager.m
//  CPGpnCommandManager
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

#import "CPGpnCommandManager.h"

#import "CPCommon.h"

@interface CPGpnCommand (CommandManager)

- (void)execute;
- (void)cancel;
- (void)setCallback:(CPGpnCommandCallback)callback;

@end

@interface CPGpnCommandManager ()
{
    NSMutableArray * _commands;
}

@end

@implementation CPGpnCommandManager

- (id)init
{
    self = [super init];
    if (self) {
        _commands = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [self cancelAllCommands];
    
}

#pragma mark -
#pragma mark Commands

- (void)executeCommand:(CPGpnCommand *)command callback:(CPGpnCommandCallback)callback
{
    CPLogDebug(CPTagCommands, @"Execute command: '%@' params: %@", command.type, command.parameters);
    
    [_commands addObject:command];
    [command setCallback:^(CPGpnCommand *cmd, NSError *error) {
        callback(cmd, error);
        CPLogDebug(CPTagCommands, @"Command finished: '%@' params: %@ %@",
                   cmd.type,
                   cmd.parameters,
                   cmd.cancelled ? @"cancelled:YES" : (error != nil ? ([NSString stringWithFormat:@"error: %@", [error description]]) : @""));
        [self commandDidFinish:cmd];
    }];
    [command execute];
}

- (BOOL)cancelCommandWithId:(NSString *)commandId
{
    for (CPGpnCommand *command in _commands)
    {
        if ([command.commandId isEqualToString:commandId])
        {
            return [self cancelCommand:command];
        }
    }
    return NO;
}

- (BOOL)cancelCommand:(CPGpnCommand *)command
{
    if (!command.cancelled) {
        CPLogDebug(CPTagCommands, @"Cancel command: '%@' params: %@", command.type, command.parameters);
        [command cancel];
        return YES;
    }
    
    return NO;
}

- (void)cancelAllCommands
{
    if (_commands.count > 0) {
        CPLogDebug(CPTagCommands, @"Cancel all commands: %d", _commands.count);
        
        NSArray * temp = [[NSArray alloc] initWithArray:_commands];
        for (CPGpnCommand *command in temp) {
            if (!command.cancelled) {
                [command cancel];
            }
        }
        [_commands removeAllObjects];
    }
}

- (void)commandDidFinish:(CPGpnCommand *)command
{
    [command setCallback:nil];
    [_commands removeObject:command];
    [self onCommandFinish:command];
}

- (void)onCommandFinish:(CPGpnCommand *)command
{
    // used for unit testing (quicker than method swizzling)
}

#pragma mark -
#pragma mark Properties

- (NSInteger)count
{
    return _commands.count;
}

- (NSArray *)commands
{
    return _commands;
}

@end
