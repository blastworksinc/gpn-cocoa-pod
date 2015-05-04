//
//  NSMutableDictionary_Types.m
//  NSMutableDictionary_Types
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

#import "NSMutableDictionary_Types.h"

#import "CPCommon.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

void CPSafeSetObject(NSMutableDictionary *dict, id object, id key)
{
    if (key != nil && object != nil)
    {
        [dict setObject:object forKey:key];
    }
    else
    {
        CPAssertMsgv(key != nil && object != nil, @"Attempt to set key/value pair: %@=%@", key, object);
    }
}

void CPTrySetObject(NSMutableDictionary *dict, id object, id key)
{
    if (key != nil)
    {
        if (object != nil)
        {
            [dict setObject:object forKey:key];
        }
    }
    else
    {
        CPAssertMsgv(key != nil, @"Tried to set object with null key: %@", object);
    }
}

void CPSetInteger(NSMutableDictionary *dict, NSInteger value, id key)
{
    NSNumber *number = [[NSNumber alloc] initWithInt:value];
    CPSafeSetObject(dict, number, key);
}

void CPSetBoolean(NSMutableDictionary *dict, BOOL value, id key)
{
    NSNumber *number = [[NSNumber alloc] initWithBool:value];
    CPSafeSetObject(dict, number, key);
}

void CPSetFloat(NSMutableDictionary *dict, float value, id key)
{
    NSNumber *number = [[NSNumber alloc] initWithFloat:value];
    CPSafeSetObject(dict, number, key);
}

#pragma clang diagnostic pop
