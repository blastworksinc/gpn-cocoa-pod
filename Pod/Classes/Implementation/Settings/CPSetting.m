//
//  CPSetting.m
//  CPSetting
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

#import "CPCommon.h"
#import "CPSetting.h"

#define kEncodeNSString  @"@\"NSString\""
#define kEncodeNSURL     @"@\"NSURL\""

@implementation CPSetting

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _enabled = YES;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [self init]; // setup defaults first
    if (self)
    {
        if (![self parseFromDictionary:dict] || ![self checkValues])
        {
            self = nil;
            return nil;
        }
    }
    return self;
}

- (BOOL)checkValues
{
    return YES;
}

- (BOOL)parseFromDictionary:(NSDictionary *)dict
{
    Class parentClass = [self class];
    while ([(parentClass = [parentClass superclass]) isSubclassOfClass:[CPSetting class]])
    {
        if (![self class:parentClass parseFromDictionary:dict])
        {
            return NO;
        }
    }
    
    return [self class:[self class] parseFromDictionary:dict];
}

- (BOOL)class:(Class)cls parseFromDictionary:(NSDictionary *)dict
{
    NSDictionary *properties = CPRuntimeGetPropertiesMap(cls);
    for (id key in dict)
    {
        CPPropertyInfo *property = [properties objectForKey:key];
        if (!property)
        {
            continue;
        }
        
        id value = [dict objectForKey:key];
        if (![self setValue:value forProperty:property])
        {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark -
#pragma mark Helpers

- (BOOL)setValue:(id)value forProperty:(CPPropertyInfo *)property
{
    const char* ctype = property.typeString.UTF8String;
    NSString *varName  = property.backedName;
    if (ctype && varName)
    {
        #define CHECK_ENCODE_TYPE(TYPE) (strcmp(@encode(TYPE), ctype) == 0)
        
        if (CHECK_ENCODE_TYPE(BOOL))
        {
            return [self setBoolValue:value forField:varName];
        }
        if (CHECK_ENCODE_TYPE(NSInteger))
        {
            return [self setIntegerValue:value forField:varName];
        }
        if (CHECK_ENCODE_TYPE(NSUInteger))
        {
            return [self setUnsignedIntegerValue:value forField:varName];
        }
        if (CHECK_ENCODE_TYPE(float))
        {
            return [self setFloatValue:value forField:varName];
        }
        if (CHECK_ENCODE_TYPE(double))
        {
            return [self setDoubleValue:value forField:varName];
        }
        if ([property.typeString isEqualToString:kEncodeNSString])
        {
            return [self setStringValue:value forField:varName];
        }
        if ([property.typeString isEqualToString:kEncodeNSURL])
        {
            return [self setURLValue:value forField:varName];
        }
    }
    
    return NO;
}

- (BOOL)setBoolValue:(id)value forField:(NSString *)fieldName
{
    NSString *strValue = [value description];
    
    BOOL boolValue;
    if ([strValue isEqualToString:@"1"])
    {
        boolValue = YES;
    }
    else if ([strValue isEqualToString:@"0"])
    {
        boolValue = NO;
    }
    else
    {
        return NO;
    }
    
    BOOL *ptr = (BOOL *)CPRuntimeGetPrimitiveFieldPtr(self, fieldName);
    if (ptr)
    {
        *ptr = boolValue;
        return YES;
    }
    
    return NO;
}

- (BOOL)setIntegerValue:(id)value forField:(NSString *)fieldName
{
    NSString *strValue = [value description];
    
    NSInteger outValue;
    if (CPStringParseInteger(strValue, &outValue))
    {
        NSInteger *ptr = (NSInteger *)CPRuntimeGetPrimitiveFieldPtr(self, fieldName);
        if (ptr)
        {
            *ptr = outValue;
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)setUnsignedIntegerValue:(id)value forField:(NSString *)fieldName
{
    NSString *strValue = [value description];
    
    NSInteger outValue;
    if (CPStringParseInteger(strValue, &outValue) && outValue >= 0)
    {
        NSUInteger *ptr = (NSUInteger *)CPRuntimeGetPrimitiveFieldPtr(self, fieldName);
        if (ptr)
        {
            *ptr = outValue;
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)setFloatValue:(id)value forField:(NSString *)fieldName
{
    NSString *strValue = [value description];
    
    float outValue;
    if (CPStringParseFloat(strValue, &outValue))
    {
        float *ptr = (float *)CPRuntimeGetPrimitiveFieldPtr(self, fieldName);
        if (ptr)
        {
            *ptr = outValue;
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)setDoubleValue:(id)value forField:(NSString *)fieldName
{
    NSString *strValue = [value description];
    
    float outValue;
    if (CPStringParseFloat(strValue, &outValue))
    {
        double *ptr = (double *)CPRuntimeGetPrimitiveFieldPtr(self, fieldName);
        if (ptr)
        {
            *ptr = outValue;
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)setStringValue:(id)value forField:(NSString *)fieldName
{
    NSString *strValue = [value description];
    [self setValue:strValue forKey:fieldName];
    return YES;
}

- (BOOL)setURLValue:(id)value forField:(NSString *)fieldName
{
    NSString *strValue = [value description];
    NSURL *url = [NSURL URLWithString:strValue];
    if (url != nil)
    {
        [self setValue:url forKey:fieldName];
        return YES;
    }
    
    return NO;
}

@end
