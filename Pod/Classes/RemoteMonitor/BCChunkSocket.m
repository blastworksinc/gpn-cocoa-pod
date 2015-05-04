//
//  BCChunkSocket.m
//  BCChunkSocket
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

#include <ifaddrs.h>
#include <arpa/inet.h>

#import <UIKit/UIKit.h>

#import "BCChunkSocket.h"

#import "GCDAsyncSocket.h"

#import "BCChunk.h"
#import "BCChunkConnection.h"
#import "BCChunkRegistry.h"

#import "BCDataInput.h"
#import "BCDataOuput.h"

#import "BCChunks.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

@interface BCChunkSocket() <CP_GCDAsyncSocketDelegate, BCChunkConnectionDelegate>
{
    CP_GCDAsyncSocket    * _socket;
    
    dispatch_queue_t _delegateQueue;
}

@end

@implementation BCChunkSocket

- (id)initWithDelegate:(id<BCChunkSocketDelegate>)delegate andDelegateQeueu:(dispatch_queue_t)queue
{
    self = [super init];
    if (self)
    {
        _delegate = delegate;
        _delegateQueue = queue;
        dispatch_retain(queue);
    }
    return self;
}

- (BOOL)acceptOnPort:(uint16_t)port error:(NSError **)errPtr
{
    _socket = [[CP_GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_delegateQueue];
    BOOL succeed = [_socket acceptOnPort:port error:errPtr];
    if (succeed)
    {
        BCChunkRegistry *registry = [BCChunkRegistry sharedInstance]; // TODO: move it out
        [registry registerChunkName:kBCLogChunkName toClass:[BCLogChunk class]];
        [registry registerChunkName:kBCTimerChunkName toClass:[BCTimerChunk class]];
        [registry registerChunkName:kBCEventChunkName toClass:[BCEventChunk class]];
    }
    
    return succeed;
}

- (BOOL)connectToHost:(NSString *)host onPort:(uint16_t)port error:(NSError **)errPtr
{
    _socket = [[CP_GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_delegateQueue];
    BOOL succeed = [_socket connectToHost:host onPort:port error:errPtr];
    return succeed;
}

- (uint16_t)port
{
    return [_socket localPort];
}

- (void)sendChunk:(BCChunk *)chunk
{
    NSOutputStream *dataStream = [[NSOutputStream alloc] initToMemory];
    [dataStream open];

    NSError *error = nil;
    if ([chunk writeToStream:dataStream error:&error])
    {
        NSData *chunkData = [dataStream propertyForKey: NSStreamDataWrittenToMemoryStreamKey];
        
        NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
        [stream open];

        const uint8_t buffer[4] = {
            [chunk.name characterAtIndex:0],
            [chunk.name characterAtIndex:1],
            [chunk.name characterAtIndex:2],
            [chunk.name characterAtIndex:3],
        };
        [stream write:buffer maxLength:4];
        
        BCWriteInt(stream, chunkData.length);
        [stream write:chunkData.bytes maxLength:chunkData.length];

        NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
        
        [_socket writeData:data withTimeout:-1 tag:0];
        [stream close];
    }
    else
    {
        NSLog(@"Can't write chunk: %@", error);
    }
    
    [dataStream close];
}

#pragma mark -
#pragma mark GCDAsyncSocketDelegate

/**
 * Called when a socket accepts a connection.
 * Another socket is automatically spawned to handle it.
 *
 * You must retain the newSocket if you wish to handle the connection.
 * Otherwise the newSocket instance will be released and the spawned connection will be closed.
 *
 * By default the new socket will have the same delegate and delegateQueue.
 * You may, of course, change this at any time.
 **/
- (void)socket:(CP_GCDAsyncSocket *)sock didAcceptNewSocket:(CP_GCDAsyncSocket *)newSocket
{
    NSLog(@"Did accept new socket");
    BCChunkConnection *connection = [[BCChunkConnection alloc] initWithSocket:newSocket];
    connection.delegate = self;
    newSocket.userData = connection;
    
    if ([_delegate respondsToSelector:@selector(socket:didAcceptNewConnection:)])
    {
        [_delegate socket:self didAcceptNewConnection:connection];
    }
    [connection startReading];
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(CP_GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    BCChunkConnection *connection = sock.userData;
    [connection didReadData:data tag:tag];
}

/**
 * Called when a socket disconnects with or without error.
 *
 * If you call the disconnect method, and the socket wasn't already disconnected,
 * this delegate method will be called before the disconnect method returns.
 **/
- (void)socketDidDisconnect:(CP_GCDAsyncSocket *)sock withError:(NSError *)err
{
    BCChunkConnection *connection = (BCChunkConnection *)sock.userData;
    if ([_delegate respondsToSelector:@selector(socket:didCloseConnection:)])
    {
        [_delegate socket:self didCloseConnection:connection];
    }
    sock.userData = nil;
}

#pragma mark -
#pragma mark BCChunkConnectionDelegate

- (void)connection:(BCChunkConnection *)connection didReceiveChunk:(BCChunk *)chunk
{
    [_delegate connection:connection didReceiveChunk:chunk];
}

- (void)connection:(BCChunkConnection *)connection didFailToReceiveChunkName:(NSString *)chunkName withError:(NSError *)error
{
}

@end

#pragma clang diagnostic pop