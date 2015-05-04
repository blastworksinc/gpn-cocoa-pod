//
//  BCRemoteMonitor.m
//  BCRemoteMonitor
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

#import "BCRemoteMonitor.h"

#import "BCChunks.h"
#import "BCChunkSocket.h"

static BCRemoteMonitor *instance;

@interface BCRemoteMonitor () <BCChunkSocketDelegate>
{
    BCChunkSocket * _chunkSocket;
}

@end

@implementation BCRemoteMonitor

+ (void)connectToHost:(NSString *)host port:(uint16_t)port
{
    if (instance == nil) {
        instance = [[BCRemoteMonitor alloc] init];
        [instance connectToHost:host onPort:port];
    }
}

+ (void)disconnect
{
    [instance disconnectFromHost];
    instance = nil;
}

+ (BOOL)isConnected
{
    return instance != nil;
}

#pragma mark -
#pragma mark Connection

- (void)connectToHost:(NSString *)host onPort:(uint16_t)port
{
    _chunkSocket = [[BCChunkSocket alloc] initWithDelegate:self andDelegateQeueu:dispatch_get_main_queue()];

    NSError *error = nil;
    BOOL succeed = [_chunkSocket connectToHost:host onPort:port error:&error];
    if (succeed)
    {
        NSLog(@"Connected to remote monitor");
    }
    else
    {
        NSLog(@"Don't connected to remote monitor: %@", error);
    }
}

- (void)disconnectFromHost
{
    // TODO
}

#pragma mark -
#pragma mark Chunks

- (void)sendChunk:(BCChunk *)chunk
{
    [_chunkSocket sendChunk:chunk];
}

+ (void)sendLogLevel:(int)level thread:(NSString *)thread message:(NSString *)message
{
    BCLogChunk *logChunk = [[BCLogChunk alloc] initWithMessage:message];
    
    logChunk.level = (BCLogLevel)level;
    logChunk.thread = thread;
    logChunk.date = [NSDate date];
    
    [instance sendChunk:logChunk];
}

#pragma mark -
#pragma mark BCChunkSocketDelegate

- (void)connection:(BCChunkConnection *)connection didReceiveChunk:(BCChunk *)chunk
{
    
}

@end
