//
//  BCTimerChunk.h
//  BCTimerChunk
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

typedef NS_ENUM(NSInteger, BCTimerChunkType) {
    BCTimerChunkTypeNone = 0,
    BCTimerChunkTypeSchedule,
    BCTimerChunkTypeSuspend,
    BCTimerChunkTypeResume,
    BCTimerChunkTypeFire,
    BCTimerChunkTypeFinish,
    BCTimerChunkTypeCancel,
    BCTimerChunkTypeSample,
};

@interface BCTimerChunk : BCIDChunk

@property (nonatomic, assign) BCTimerChunkType type;
@property (nonatomic, retain) NSString *timerName;
@property (nonatomic, assign) NSInteger delay;
@property (nonatomic, assign) NSInteger remaining;
@property (nonatomic, assign) BOOL suspended;
@property (nonatomic, assign) BOOL ticksWhenSuspended;

@end

@interface BCTimerChunkSerializer : NSObject

@property (nonatomic, readonly) BCTimerChunkType type;
@property (nonatomic, readonly) NSString *name;

@property (nonatomic, copy) BOOL (^readerBlock)(NSInputStream *stream, BCTimerChunk *chunk, NSError **errPtr);
@property (nonatomic, copy) BOOL (^writerBlock)(NSOutputStream *stream, BCTimerChunk *chunk, NSError **errPtr);

- (instancetype)initWithType:(BCTimerChunkType)type andName:(NSString *)name;

@end
