//
//  BCChunkConnection.m
//  BCChunkConnection
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

#import "BCChunkConnection.h"

#import "GCDAsyncSocket.h"
#import "BCChunk.h"

#import "BCDataInput.h"
#import "BCChunkRegistry.h"

static const int kHeaderLength  = 8;
static const int kHeaderTag     = 1;
static const int kPayloadTag    = 2;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"

NSString * const BCChunkConnectionErrorDomain = @"BCChunkConnectionErrorDomain";

@interface BCChunkConnection ()
{
    CP_GCDAsyncSocket * _socket;
    NSTimeInterval _timeout;
    NSMutableData * _buffer;
}

@end

@implementation BCChunkConnection

- (id)initWithSocket:(CP_GCDAsyncSocket *)socket
{
    self = [super init];
    if (self)
    {
        _socket = socket;
        _timeout = -1;
        _buffer = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)startReading
{
    [self requestHeader];
}

- (void)didReadData:(NSData *)data tag:(long)tag
{
    [_buffer appendData:data];
    
    switch (tag)
    {
        case kHeaderTag:
        {
            // d'oh!
            const uint8_t *bytes = [data bytes]; // char[4] + int
            int length = bytes[4] << 24 | bytes[5] << 16 | bytes[6] << 8 | bytes[7];
            [self requestPayloadWithLength:length];
            break;
        }
            
        case kPayloadTag:
        {
            [self chunkBytesDidReceive:_buffer];
            [self requestHeader];
            break;
        }
    }
}

- (void)chunkBytesDidReceive:(NSData *)data
{
    NSInputStream *stream = nil;
    #if __has_feature(cxx_exceptions)
    @try
    #endif
    {
        stream = [[NSInputStream alloc] initWithData:data];
        [stream open];
        
        NSString *name;
        NSError *error = nil;
        if (!BCReadBytes(stream, &name, 4, &error))
        {
            [self notifyChunkName:nil didFailWithError:error];
            return;
        }
        
        NSInteger length;
        if (!BCReadInt(stream, &length, &error))
        {
            [self notifyChunkName:name didFailWithError:error];
            return;
        }
        
        BCChunk *chunk = [[BCChunkRegistry sharedInstance] chunkForName:name];
        if (!chunk)
        {
            error = [NSError errorWithDomain:BCChunkConnectionErrorDomain code:-1 userInfo:@{
                NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Unknown chunk: '%@'", name]
            }];
            [self notifyChunkName:name didFailWithError:error];
            return;
        }
        
        BOOL succeed = [chunk readFromStream:stream error:&error];
        if (succeed)
        {
            [self notifyChunkDidReceive:chunk];
        }
        else
        {
            [self notifyChunkName:name didFailWithError:error];
        }
    }
    #if __has_feature(cxx_exceptions)
    @finally
    #endif
    {
        [stream close];
    }
}

- (void)requestHeader
{
    [_buffer setLength:0];
    [self requestDataLength:kHeaderLength tag:kHeaderTag];
}

- (void)requestPayloadWithLength:(NSUInteger)length
{
    [self requestDataLength:length tag:kPayloadTag];
}

- (void)requestDataLength:(NSUInteger)length tag:(long)tag
{
    [_socket readDataToLength:length withTimeout:_timeout tag:tag];
}

#pragma mark -
#pragma mark Delegate notification

- (void)notifyChunkDidReceive:(BCChunk *)chunk
{
    if ([_delegate respondsToSelector:@selector(connection:didReceiveChunk:)]) {
        [_delegate connection:self didReceiveChunk:chunk];
    }
}

- (void)notifyChunkName:(NSString *)chunkName didFailWithError:(NSError *)error
{
    if ([_delegate respondsToSelector:@selector(connection:didFailToReceiveChunkName:withError:)]) {
        [_delegate connection:self didFailToReceiveChunkName:chunkName withError:error];
    }
}

@end

#pragma clang diagnostic pop