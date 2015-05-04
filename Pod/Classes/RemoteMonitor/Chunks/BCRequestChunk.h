//
//  BCRequestChunk.h
//  BCRequestChunk
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

#import "BCIDChunk.h"

typedef NS_ENUM(NSInteger, BCRequestChunkType) {
    BCRequestChunkTypeNone = 0,
    BCRequestChunkTypeQueued,
    BCRequestChunkTypeFinished,
    BCRequestChunkTypeFailed,
    BCRequestChunkTypeCancelled,
};

@interface BCRequestChunk : BCIDChunk

@property (nonatomic, assign) BCRequestChunkType type;

@property (nonatomic, retain) NSString *requestName;
@property (nonatomic, retain) NSString *URLString;

@property (nonatomic, retain) NSDictionary *params;
@property (nonatomic, retain) NSDictionary *headers;

@property (nonatomic, assign) int duration;

@property (nonatomic, retain) NSString *errorName;
@property (nonatomic, retain) NSString *errorMessage;

- (id)initWithType:(BCRequestChunkType)type;

@end

@interface BCRequestChunkSerializer : NSObject

@property (nonatomic, readonly) BCRequestChunkType type;
@property (nonatomic, readonly) NSString *name;

@property (nonatomic, copy) BOOL (^readerBlock)(NSInputStream *stream, BCRequestChunk *chunk, NSError **errPtr);
@property (nonatomic, copy) BOOL (^writerBlock)(NSOutputStream *stream, BCRequestChunk *chunk, NSError **errPtr);

- (instancetype)initWithType:(BCRequestChunkType)type andName:(NSString *)name;

@end
