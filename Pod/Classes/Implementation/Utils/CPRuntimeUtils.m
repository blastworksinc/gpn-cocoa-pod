//
//  CPRuntimeUtils.m
//  CPRuntimeUtils
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

#import <objc/runtime.h>

#import "CPRuntimeUtils.h"

NSArray *CPRuntimeGetPropertiesList(Class cls)
{
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList(cls, &outCount);
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:outCount];
    for (int i = 0; i < outCount; ++i)
    {
        objc_property_t prop = properties[i];
        
        const char* name = property_getName(prop);
        if (!name)
        {
            continue;
        }
        
        const char* attributes = property_getAttributes(prop);
        if (!attributes)
        {
            continue;
        }
        
        [array addObject:[[CPPropertyInfo alloc] initWithPropertyName:name andAttributes:attributes]];
        
    }
    free(properties);
    
    return array;
}

NSDictionary *CPRuntimeGetPropertiesMap(Class cls)
{
    NSArray *list = CPRuntimeGetPropertiesList(cls);
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:list.count];
    for (CPPropertyInfo *p in list)
    {
        [dict setObject:p forKey:p.name];
    }
    return dict;
}

void* CPRuntimeGetPrimitiveFieldPtr(id object, NSString *fieldName)
{
    if (object == nil || fieldName == nil)
    {
        return NULL;
    }
    Ivar var = class_getInstanceVariable([object class], fieldName.UTF8String);
    if (var)
    {
        return (void *)((uint8_t *)(__bridge void *)object + ivar_getOffset(var));
    }
    
    return NULL;
}

@implementation CPPropertyInfo

- (instancetype)initWithPropertyName:(const char *)name andAttributes:(const char *)attributes
{
    self = [super init];
    if (self)
    {
        if (!name || !attributes || ![self parseAttributes:attributes])
        {
            self = nil;
            return nil;
        }
        
        _name = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
    }
    return self;
}

- (BOOL)parseAttributes:(const char *)attributesStr
{
    NSString *attributes = [NSString stringWithCString:attributesStr encoding:NSASCIIStringEncoding];
    NSArray *tokens = [attributes componentsSeparatedByString:@","];
    if (tokens.count < 2)
    {
        return NO;
    }
    
    NSString *firstToken = [tokens objectAtIndex:0];
    if (firstToken.length < 2 || ![firstToken hasPrefix:@"T"])
    {
        return NO;
    }

    NSString *lastToken = [tokens objectAtIndex:tokens.count - 1];
    if (lastToken.length < 2 || ![lastToken hasPrefix:@"V"])
    {
        return NO;
    }
    
    _typeString = [firstToken substringFromIndex:1];
    _backedName = [lastToken substringFromIndex:1];
    
    for (int i = 1; i < tokens.count - 1; ++i)
    {
        NSString *token = [tokens objectAtIndex:i];
        if (token.length == 0)
        {
            return NO;
        }
        
        switch ([token characterAtIndex:0])
        {
            case 'R': _flags |= CPPropertyInfoReadonly; break;
            case 'C': _flags |= CPPropertyInfoCopy; break;
            case '&': _flags |= CPPropertyInfoRetain; break;
            case 'N': _flags |= CPPropertyInfoNonatomic; break;
            case 'D': _flags |= CPPropertyInfoDynamic; break;
            case 'G':
                _customGetter = [token substringWithRange:NSMakeRange(1, token.length-1)];
                break;
            case 'S':
                _customSetter = [token substringWithRange:NSMakeRange(1, token.length-1)];
                break;
        }
    }
    
    return YES;
}

#pragma mark -
#pragma mark Properties

- (BOOL)isReadonly
{
    return _flags & CPPropertyInfoReadonly;
}

- (BOOL)isCopy
{
    return _flags & CPPropertyInfoCopy;
}

- (BOOL)isRetain
{
    return _flags & CPPropertyInfoRetain;
}

- (BOOL)isNonatomic
{
    return _flags & CPPropertyInfoNonatomic;
}

- (BOOL)isDynamic
{
    return _flags & CPPropertyInfoDynamic;
}

- (BOOL)isWeak
{
    return _flags & CPPropertyInfoWeak;
}

@end
