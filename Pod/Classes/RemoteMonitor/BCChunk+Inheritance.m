//
//  BCChunk+Inheritance.m
//  BCChunk+Inheritance
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"

BOOL BCChunkReadUTF(NSInputStream *stream, NSString **ptr, NSError **errPtr)
{
    BOOL notNil;
    if (!BCReadBool(stream, &notNil, errPtr))
    {
        return NO;
    }
    
    if (notNil)
    {
        NSString *value;
        if (BCReadString(stream, &value, errPtr))
        {
            *ptr = value;
            return YES;
        }
    }
    else
    {
        *ptr = nil;
    }
    
    return YES;
}

BOOL BCChunkWriteUTF(NSOutputStream *stream, NSString *value, NSError **errPtr)
{
    BOOL notNil = value != nil;
    if (!BCWriteBool(stream, notNil))
    {
        return NO;
    }
    
    if (notNil)
    {
        if (!BCWriteString(stream, value))
        {
            return NO;
        }
    }
    
    return YES;
}

BOOL BCChunkReadDictionary(NSInputStream *stream, NSDictionary **ptr, NSError **errPtr)
{
    BOOL notNil;
    if (!BCReadBool(stream, &notNil, errPtr))
    {
        return NO;
    }
    
    if (notNil)
    {
        NSInteger size;
        if (!BCReadInt(stream, &size, errPtr))
        {
            return NO;
        }
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:size];
        
        for (int i = 0; i < size; ++i)
        {
            NSString *key;
            if (!BCChunkReadUTF(stream, &key, errPtr))
            {
                return NO;
            }
            
            NSString *value;
            if (!BCChunkReadUTF(stream, &value, errPtr))
            {
                return NO;
            }
            
            if (key == nil || value == nil)
            {
                continue;
            }
            
            [dict setObject:value forKey:key];
        }
        
        *ptr = dict;
    }
    else
    {
        *ptr = nil;
    }
    
    return YES;
}

BOOL BCChunkWriteDictionary(NSOutputStream *stream, NSDictionary *dict, NSError **errPtr)
{
    BOOL notNil = dict != nil;
    if (!BCWriteBool(stream, notNil))
    {
        return NO;
    }
    
    if (notNil)
    {
        NSInteger size = dict.count;
        if (!BCWriteInt(stream, size))
        {
            return NO;
        }
        
        for (id key in dict)
        {
            if (!BCChunkWriteUTF(stream, [key description], errPtr))
            {
                return NO;
            }
            
            id value = [dict objectForKey:key];
            if (!BCChunkWriteUTF(stream, [value description], errPtr))
            {
                return NO;
            }
        }
    }
    
    return YES;
    
}

#pragma clang diagnostic pop
