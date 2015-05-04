//
//  NSDictionary_Types.m
//  NSDictionary_Types
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

#import "NSDictionary_Types.h"

static NSNumber * CPNumberForKey(NSDictionary *dict, id key)
{
    return CPObjectForKeyAndClass(dict, key, [NSNumber class]);
}

NSInteger CPIntegerForKey(NSDictionary *dict, id key)
{
    return [CPNumberForKey(dict, key) integerValue];
}

BOOL CPBooleanForKey(NSDictionary *dict, id key)
{
    return [CPNumberForKey(dict, key) boolValue];
}

float CPFloatForKey(NSDictionary *dict, id key)
{
    return [CPNumberForKey(dict, key) floatValue];
}

double CPDoubleForKey(NSDictionary *dict, id key)
{
    return [CPNumberForKey(dict, key) doubleValue];
}

NSString * CPStringForKey(NSDictionary *dict, id key)
{
    return CPObjectForKeyAndClass(dict, key, [NSString class]);
}

NSDictionary * CPDictionaryForKey(NSDictionary *dict, id key)
{
    return CPObjectForKeyAndClass(dict, key, [NSDictionary class]);
}

NSURL * CPURLForKey(NSDictionary *dict, id key)
{
    return CPObjectForKeyAndClass(dict, key, [NSURL class]);
}

id CPObjectForKeyAndClass(NSDictionary *dict, id key, Class clss)
{
    id object = [dict objectForKey:key];
    return [object isKindOfClass:clss] ? object : nil;
}
