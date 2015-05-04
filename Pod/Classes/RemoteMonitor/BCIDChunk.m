//
//  BCIDChunk.m
//  BCIDChunk
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

#import "BCDataInput.h"
#import "BCDataOuput.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

@implementation BCIDChunk

- (BOOL)readFromStream:(NSInputStream *)stream error:(NSError *__autoreleasing *)errPtr
{
    NSError *error = nil;
    NSInteger objectID;
    if(BCReadInt(stream, &objectID, &error))
    {
        _objectID = [NSNumber numberWithInt:objectID];
        return YES;
    }
    
    if (errPtr) *errPtr = error;
    return NO;
}

- (BOOL)writeToStream:(NSOutputStream *)stream error:(NSError *__autoreleasing *)errPtr
{
    return BCWriteInt(stream, [_objectID intValue]);
}

@end

#pragma clang diagnostic pop