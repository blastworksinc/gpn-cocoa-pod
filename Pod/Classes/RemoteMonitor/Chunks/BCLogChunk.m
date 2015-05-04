//
//  BCLogChunk.m
//  BCLogChunk
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

#import "BCLogChunk.h"
#import "BCChunk+Inheritance.h"

#import "BCChunks.h"
#import "BCDataInput.h"

@implementation BCLogChunk

- (id)initWithMessage:(NSString *)message
{
    self = [super initWithName:kBCLogChunkName];
    if (self)
    {
        self.message = message;
        self.level = BCLogLevelVerbose;
    }
    return self;
}

#pragma mark -
#pragma mark Stream

- (BOOL)readFromStream:(NSInputStream *)stream error:(NSError **)errPtr
{
    int level;
    if (!BCReadInt(stream, &level, errPtr))
    {
        return NO;
    }
    
    NSString *thread;
    if (!BCChunkReadUTF(stream, &thread, errPtr))
    {
        return NO;
    }
    
    NSString *message;
    if (!BCChunkReadUTF(stream, &message, errPtr))
    {
        return NO;
    }
    
    self.level   = level;
    self.thread  = thread;
    self.message = message;
    self.date    = [NSDate date];
    
    return YES;
}

- (BOOL)writeToStream:(NSOutputStream *)stream error:(NSError **)errPtr
{
    BCWriteInt(stream, _level);
    
    if (!BCChunkWriteUTF(stream, _thread, errPtr))
    {
        return NO;
    }
    
    if (!BCChunkWriteUTF(stream, _message, errPtr))
    {
        return NO;
    }
    
    return YES;
}

@end
