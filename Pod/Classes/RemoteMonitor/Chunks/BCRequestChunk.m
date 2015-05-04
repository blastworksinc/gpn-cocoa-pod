//
//  BCRequestChunk.m
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

#import "BCRequestChunk.h"

#import "BCChunk+Inheritance.h"

// None, Queued, Finished, Failed, Cancelled

static NSString * const kNone       = @"None";
static NSString * const kQueued     = @"Queued";
static NSString * const kFinished   = @"Finished";
static NSString * const kFailed     = @"Failed";
static NSString * const kCancelled  = @"Cancelled";

static NSArray      * _byTypeLookup;
static NSDictionary * _byNameLookup;

typedef BOOL (^BCRequestChunkReader)(NSInputStream *stream, BCRequestChunk *chunk, NSError **errPtr);
typedef BOOL (^BCRequestChunkWriter)(NSOutputStream *stream, BCRequestChunk *chunk, NSError **errPtr);

@implementation BCRequestChunk

- (id)initWithType:(BCRequestChunkType)type
{
    self = [super initWithName:kBCRequestChunkName];
    if (self)
    {
        _type = type;
    }
    return self;
}

#pragma mark -
#pragma mark Lookup

+ (void)initialize
{
    if ([self class] == [BCRequestChunk class])
    {
        // none
        BCRequestChunkSerializer *noneSerializer = [[BCRequestChunkSerializer alloc] initWithType:BCRequestChunkTypeNone andName:kNone];
        
        // schedule
        BCRequestChunkSerializer *queuedSerializer = [[BCRequestChunkSerializer alloc] initWithType:BCRequestChunkTypeQueued andName:kQueued];
        queuedSerializer.readerBlock = ^BOOL(NSInputStream *stream, BCRequestChunk *chunk, NSError **errPtr)
        {
            NSString *requestName;
            if (!BCChunkReadUTF(stream, &requestName, errPtr)) return NO;
            
            NSString *URLString;
            if (!BCChunkReadUTF(stream, &URLString, errPtr)) return NO;
            
            NSDictionary *params;
            if (!BCChunkReadDictionary(stream, &params, errPtr)) return NO;
            
            NSDictionary *headers;
            if (!BCChunkReadDictionary(stream, &headers, errPtr)) return NO;

            chunk.requestName   = requestName;
            chunk.URLString     = URLString;
            chunk.params        = params;
            chunk.headers       = headers;
            
            return YES;
        };
        
        queuedSerializer.writerBlock = ^BOOL(NSOutputStream *stream, BCRequestChunk *chunk, NSError **errPtr)
        {
            if (!BCChunkWriteUTF(stream, chunk.requestName, errPtr)) return NO;
            if (!BCChunkWriteUTF(stream, chunk.URLString, errPtr)) return NO;
            if (!BCChunkWriteDictionary(stream, chunk.params, errPtr)) return NO;
            if (!BCChunkWriteDictionary(stream, chunk.headers, errPtr)) return NO;
            
            return YES;
        };
        
        // finished
        BCRequestChunkSerializer *finishedSerializer = [[BCRequestChunkSerializer alloc] initWithType:BCRequestChunkTypeFinished andName:kFinished];
        finishedSerializer.readerBlock = ^BOOL(NSInputStream *stream, BCRequestChunk *chunk, NSError **errPtr)
        {
            int duration;
            if (!BCReadInt(stream, &duration, errPtr)) return NO;
            
            chunk.duration = duration;
            
            return YES;
        };
        
        finishedSerializer.writerBlock = ^BOOL(NSOutputStream *stream, BCRequestChunk *chunk, NSError **errPtr)
        {
            if (!BCWriteInt(stream, chunk.duration)) return NO; // TODO: errPtr
            
            return YES;
        };
        
        // cancelled
        BCRequestChunkSerializer *cancelledSerializer = [[BCRequestChunkSerializer alloc] initWithType:BCRequestChunkTypeCancelled andName:kCancelled];
        cancelledSerializer.readerBlock = ^BOOL(NSInputStream *stream, BCRequestChunk *chunk, NSError **errPtr)
        {
            int duration;
            if (!BCReadInt(stream, &duration, errPtr)) return NO;
            
            chunk.duration = duration;
            
            return YES;
        };
        
        cancelledSerializer.writerBlock = ^BOOL(NSOutputStream *stream, BCRequestChunk *chunk, NSError **errPtr)
        {
            if (!BCWriteInt(stream, chunk.duration)) return NO; // TODO: errPtr
            
            return YES;
        };
        
        // failed
        BCRequestChunkSerializer *failedSerializer = [[BCRequestChunkSerializer alloc] initWithType:BCRequestChunkTypeFailed andName:kFailed];
        failedSerializer.readerBlock = ^BOOL(NSInputStream *stream, BCRequestChunk *chunk, NSError **errPtr)
        {
            int duration;
            if (!BCReadInt(stream, &duration, errPtr)) return NO;
            
            NSString *errorName;
            if (!BCChunkReadUTF(stream, &errorName, errPtr)) return NO;
            
            NSString *errorMessage;
            if (!BCChunkReadUTF(stream, &errorMessage, errPtr)) return NO;
            
            chunk.duration      = duration;
            chunk.errorName     = errorName;
            chunk.errorMessage  = errorMessage;
            
            return YES;
        };
        
        failedSerializer.writerBlock = ^BOOL(NSOutputStream *stream, BCRequestChunk *chunk, NSError **errPtr)
        {
            if (!BCWriteInt(stream, chunk.duration)) return NO; // TODO: errPtr
            if (!BCChunkWriteUTF(stream, chunk.errorName, errPtr)) return NO;
            if (!BCChunkWriteUTF(stream, chunk.errorMessage, errPtr)) return NO;
            
            return YES;
        };
        
        // lookup by name
        _byNameLookup = @{
          kNone      : noneSerializer,
          kQueued    : queuedSerializer,
          kFinished  : finishedSerializer,
          kFailed    : failedSerializer,
          kCancelled : cancelledSerializer,
        };
        
        // lookup by type
        _byTypeLookup = @[
          noneSerializer,
          queuedSerializer,
          finishedSerializer,
          failedSerializer,
          cancelledSerializer,
        ];
    }
}

#pragma mark -
#pragma mark Chunk type lookup

- (BCRequestChunkSerializer *)chunkSerializerForType:(BCRequestChunkType)type
{
    if (type >= 0 && type < _byTypeLookup.count)
    {
        return [_byTypeLookup objectAtIndex:type];
    }
    
    return nil;
}

- (BCRequestChunkSerializer *)chunkSerializerForName:(NSString *)typeName
{
    return [_byNameLookup objectForKey:typeName];
}

#pragma mark -
#pragma mark IO

- (BOOL)readFromStream:(NSInputStream *)stream error:(NSError *__autoreleasing *)errPtr
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
    
    BCRequestChunkSerializer *serializer = [self chunkSerializerForName:typeName];
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

- (BOOL)writeToStream:(NSOutputStream *)stream error:(NSError *__autoreleasing *)errPtr
{
    if (![super writeToStream:stream error:errPtr])
    {
        return NO;
    }
    
    BCRequestChunkSerializer *serializer = [self chunkSerializerForType:self.type];
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

@interface BCRequestChunkSerializer ()
{
    BCRequestChunkType _type;
    NSString * _name;
}

@end

@implementation BCRequestChunkSerializer

- (instancetype)initWithType:(BCRequestChunkType)type andName:(NSString *)name
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
