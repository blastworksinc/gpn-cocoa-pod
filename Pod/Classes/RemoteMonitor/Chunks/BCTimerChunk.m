//
//  BCTimerChunk.m
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

#import "BCTimerChunk.h"

#import "BCChunk+Inheritance.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

static NSString * const kNone       = @"None";
static NSString * const kSchedule   = @"Schedule";
static NSString * const kSuspend    = @"Suspend";
static NSString * const kResume     = @"Resume";
static NSString * const kFire       = @"Fire";
static NSString * const kFinish     = @"Finish";
static NSString * const kCancel     = @"Cancel";
static NSString * const kSample     = @"Sample";

static NSArray      * _byTypeLookup;
static NSDictionary * _byNameLookup;

typedef BOOL (^BCTimerChunkReader)(NSInputStream *stream, BCTimerChunk *chunk, NSError **errPtr);
typedef BOOL (^BCTimerChunkWriter)(NSOutputStream *stream, BCTimerChunk *chunk, NSError **errPtr);

@implementation BCTimerChunk

- (id)init
{
    self = [super initWithName:kBCTimerChunkName];
    if (self)
    {
    }
    return self;
}

#pragma mark -
#pragma mark Lookup

+ (void)initialize
{
    if ([self class] == [BCTimerChunk class])
    {
        // none
        BCTimerChunkSerializer *noneSerializer = [[BCTimerChunkSerializer alloc] initWithType:BCTimerChunkTypeNone andName:kNone];
        
        // schedule
        BCTimerChunkSerializer *scheduleSerializer = [[BCTimerChunkSerializer alloc] initWithType:BCTimerChunkTypeSchedule andName:kSchedule];
        scheduleSerializer.readerBlock = ^BOOL(NSInputStream *stream, BCTimerChunk *chunk, NSError **errPtr)
        {
            NSString *timerName;
            if (!BCChunkReadUTF(stream, &timerName, errPtr)) return NO;
            
            int delay;
            if (!BCReadInt(stream, &delay, errPtr)) return NO;
            
            chunk.timerName = timerName;
            chunk.delay = delay;
            chunk.remaining = delay;
            
            return YES;
        };
        
        scheduleSerializer.writerBlock = ^BOOL(NSOutputStream *stream, BCTimerChunk *chunk, NSError **errPtr)
        {
            if (!BCChunkWriteUTF(stream, chunk.timerName, errPtr)) return NO;
            if (!BCWriteInt(stream, chunk.delay)) return NO;
            
            return YES;
        };
        
        // suspend
        BCTimerChunkSerializer *suspendSerializer = [[BCTimerChunkSerializer alloc] initWithType:BCTimerChunkTypeSuspend andName:kSuspend];
        suspendSerializer.readerBlock = ^BOOL(NSInputStream *stream, BCTimerChunk *chunk, NSError **errPtr)
        {
            int remaining;
            if (!BCReadInt(stream, &remaining, errPtr)) return NO;
            
            BOOL ticksWhenSuspended;
            if (!BCReadBool(stream, &ticksWhenSuspended, errPtr)) return NO;

            chunk.remaining = remaining;
            chunk.ticksWhenSuspended = ticksWhenSuspended;
            
            return YES;
        };
        
        suspendSerializer.writerBlock = ^BOOL(NSOutputStream *stream, BCTimerChunk *chunk, NSError **errPtr)
        {
            if (!BCWriteInt(stream, chunk.remaining)) return NO;
            if (!BCWriteBool(stream, chunk.ticksWhenSuspended)) return NO;
            
            return YES;
        };
        
        // resume
        BCTimerChunkSerializer *resumeSerializer = [[BCTimerChunkSerializer alloc] initWithType:BCTimerChunkTypeResume andName:kResume];
        resumeSerializer.readerBlock = ^BOOL(NSInputStream *stream, BCTimerChunk *chunk, NSError **errPtr)
        {
            int remaining;
            if (!BCReadInt(stream, &remaining, errPtr)) return NO;
            
            chunk.remaining = remaining;
            return YES;
        };
        
        resumeSerializer.writerBlock = ^BOOL(NSOutputStream *stream, BCTimerChunk *chunk, NSError **errPtr)
        {
            if (!BCWriteInt(stream, chunk.remaining)) return NO;
            return YES;
        };
        
        // fire
        BCTimerChunkSerializer *fireSerializer = [[BCTimerChunkSerializer alloc] initWithType:BCTimerChunkTypeFire andName:kFire];

        // finish
        BCTimerChunkSerializer *finishSerializer = [[BCTimerChunkSerializer alloc] initWithType:BCTimerChunkTypeFinish andName:kFinish];
        
        // cancel
        BCTimerChunkSerializer *cancelSerializer = [[BCTimerChunkSerializer alloc] initWithType:BCTimerChunkTypeCancel andName:kCancel];
        cancelSerializer.readerBlock = ^BOOL(NSInputStream *stream, BCTimerChunk *chunk, NSError **errPtr)
        {
            int remaining;
            if (!BCReadInt(stream, &remaining, errPtr)) return NO;
            
            chunk.remaining = remaining;
            return YES;
        };
        
        cancelSerializer.writerBlock = ^BOOL(NSOutputStream *stream, BCTimerChunk *chunk, NSError **errPtr)
        {
            if (!BCWriteInt(stream, chunk.remaining)) return NO;
            return YES;
        };
        
        // sample
        BCTimerChunkSerializer *sampleSerializer = [[BCTimerChunkSerializer alloc] initWithType:BCTimerChunkTypeSample andName:kSample];
        sampleSerializer.readerBlock = ^BOOL(NSInputStream *stream, BCTimerChunk *chunk, NSError **errPtr)
        {
            int remaining;
            if (!BCReadInt(stream, &remaining, errPtr)) return NO;
            
            chunk.remaining = remaining;
            return YES;
        };
        
        sampleSerializer.writerBlock = ^BOOL(NSOutputStream *stream, BCTimerChunk *chunk, NSError **errPtr)
        {
            if (!BCWriteInt(stream, chunk.remaining)) return NO;
            return YES;
        };
        
        // lookup by name
        _byNameLookup = @{
            kSchedule : scheduleSerializer,
            kSuspend  : suspendSerializer,
            kResume   : resumeSerializer,
            kFire     : fireSerializer,
            kFinish   : finishSerializer,
            kCancel   : cancelSerializer,
            kSample   : sampleSerializer,
        };
        
        // lookup by type
        _byTypeLookup = @[
            noneSerializer,
            scheduleSerializer,
            suspendSerializer,
            resumeSerializer,
            fireSerializer,
            finishSerializer,
            cancelSerializer,
            sampleSerializer,
        ];
    }
}

#pragma mark -
#pragma mark Chunk type lookup

- (BCTimerChunkSerializer *)chunkSerializerForType:(BCTimerChunkType)type
{
    if (type >= 0 && type < _byTypeLookup.count)
    {
        return [_byTypeLookup objectAtIndex:type];
    }
    
    return nil;
}

- (BCTimerChunkSerializer *)chunkSerializerForName:(NSString *)typeName
{
    return [_byNameLookup objectForKey:typeName];
}

#pragma mark -
#pragma mark IO

- (BOOL)readFromStream:(NSInputStream *)stream error:(NSError **)errPtr
{
    if (![super readFromStream:stream error:errPtr])
    {
        return NO;
    }
    
    NSString *typeName;
    if (!BCChunkReadUTF(stream, &typeName, errPtr))
    {
        return NO;
    }
    
    BCTimerChunkSerializer *serializer = [self chunkSerializerForName:typeName];
    if (!serializer)
    {
        return NO; // TODO: error
    }
    
    self.type = serializer.type;
    
    if (!serializer.readerBlock)
    {
        return YES; // don't need any data
    }
    
    return serializer.readerBlock(stream, self, errPtr);
}

- (BOOL)writeToStream:(NSOutputStream *)stream error:(NSError **)errPtr
{
    if (![super writeToStream:stream error:errPtr])
    {
        return NO;
    }
    
    BCTimerChunkSerializer *serializer = [self chunkSerializerForType:self.type];
    if (!serializer)
    {
        return NO; // TODO: error
    }
    
    if (!BCChunkWriteUTF(stream, serializer.name, errPtr))
    {
        return NO;
    }
    
    if (!serializer.writerBlock)
    {
        return YES; // don't need any data
    }
    
    return serializer.writerBlock(stream, self, errPtr);
}

@end

@interface BCTimerChunkSerializer ()
{
    BCTimerChunkType _type;
    NSString * _name;
}

@end

@implementation BCTimerChunkSerializer

- (instancetype)initWithType:(BCTimerChunkType)type andName:(NSString *)name
{
    self = [super init];
    if (self)
    {
        _type = type;
        _name = name;
    }
    return self;
}

@end

#pragma clang diagnostic pop