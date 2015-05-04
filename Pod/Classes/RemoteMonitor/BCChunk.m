//
//  BCChunk.m
//  BCChunk
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

NSString * const BCChunkErrorDomain = @"BCChunkErrorDomain";

@interface BCChunk ()
{
    NSString * _name;
}

@end

@implementation BCChunk

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if (self)
    {
        _name = name;
    }
    
    return self;
}

#pragma mark -
#pragma mark IO

- (BOOL)readFromStream:(NSInputStream *)stream error:(NSError **)errPtr
{
    if (errPtr)
    {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"Chunk reader is not implemented" };
        *errPtr = [NSError errorWithDomain:BCChunkErrorDomain code:-1 userInfo:userInfo];
    }
    return NO;
}

- (BOOL)writeToStream:(NSOutputStream *)stream error:(NSError **)errPtr
{
    if (errPtr)
    {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"Chunk writer is not implemented" };
        *errPtr = [NSError errorWithDomain:BCChunkErrorDomain code:-1 userInfo:userInfo];
    }
    return NO;
}

@end
