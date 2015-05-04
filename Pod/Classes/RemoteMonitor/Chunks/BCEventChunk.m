//
//  BCEventChunk.m
//  BCEventChunk
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

#import "BCChunk+Inheritance.h"

#import "BCEventChunk.h"

@implementation BCEventChunk

- (id)initWithEventName:(NSString *)name andParams:(NSDictionary *)params
{
    self = [super initWithName:kBCEventChunkName];
    if (self)
    {
        _eventName  = name;
        _params     = params;
    }
    return self;
}

#pragma mark -
#pragma mark IO

- (BOOL)writeToStream:(NSOutputStream *)stream error:(NSError *__autoreleasing *)errPtr
{
    if (!BCChunkWriteUTF(stream, _eventName, errPtr))
    {
        return NO;
    }
    
    if (!BCChunkWriteDictionary(stream, _params, errPtr))
    {
        return NO;
    }
    
    return YES;
}

- (BOOL)readFromStream:(NSInputStream *)stream error:(NSError *__autoreleasing *)errPtr
{
    NSString *eventName;
    if (!BCChunkReadUTF(stream, &eventName, errPtr))
    {
        return NO;
    }
    
    NSDictionary *params;
    if (!BCChunkReadDictionary(stream, &params, errPtr))
    {
        return NO;
    }
    
    _eventName  = eventName;
    _params     = params;
    
    return YES;
}

@end
