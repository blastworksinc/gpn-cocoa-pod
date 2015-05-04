//
//  BCChunkSocket.h
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

#import <Foundation/Foundation.h>

@class BCChunk;
@class BCChunkConnection;

@protocol BCChunkSocketDelegate;

@interface BCChunkSocket : NSObject

@property (nonatomic, assign) id<BCChunkSocketDelegate> delegate;

- (id)initWithDelegate:(id<BCChunkSocketDelegate>)delegate andDelegateQeueu:(dispatch_queue_t)queue;

- (BOOL)acceptOnPort:(uint16_t)port error:(NSError **)errPrt;
- (BOOL)connectToHost:(NSString *)host onPort:(uint16_t)port error:(NSError **)errPtr;

- (void)sendChunk:(BCChunk *)chunk;

- (uint16_t)port;

@end

@protocol BCChunkSocketDelegate <NSObject>

@required
- (void)connection:(BCChunkConnection *)connection didReceiveChunk:(BCChunk *)chunk;

@optional
- (void)socket:(BCChunkSocket *)socket didAcceptNewConnection:(BCChunkConnection *)connection;
- (void)socket:(BCChunkSocket *)socket didCloseConnection:(BCChunkConnection *)connection;

@end
