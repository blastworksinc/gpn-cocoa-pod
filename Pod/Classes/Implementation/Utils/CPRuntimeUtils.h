//
//  CPRuntimeUtils.h
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

#import <Foundation/Foundation.h>

NSArray *CPRuntimeGetPropertiesList(Class cls);
NSDictionary *CPRuntimeGetPropertiesMap(Class cls);
void* CPRuntimeGetPrimitiveFieldPtr(id object, NSString *fieldName);

typedef enum : NSUInteger {
    CPPropertyInfoReadonly  = 1 << 0,
    CPPropertyInfoCopy      = 1 << 1,
    CPPropertyInfoRetain    = 1 << 2,
    CPPropertyInfoNonatomic = 1 << 3,
    CPPropertyInfoDynamic   = 1 << 4,
    CPPropertyInfoWeak      = 1 << 5,
} CPPropertyInfoFlags;

@interface CPPropertyInfo : NSObject

@property (nonatomic, readonly) BOOL isReadonly; /* The property is read-only (readonly). */
@property (nonatomic, readonly) BOOL isCopy; /* The property is a copy of the value last assigned (copy). */
@property (nonatomic, readonly) BOOL isRetain; /* The property is a reference to the value last assigned (retain). */
@property (nonatomic, readonly) BOOL isNonatomic; /* The property is non-atomic (nonatomic). */
@property (nonatomic, readonly) BOOL isDynamic; /* The property is dynamic (@dynamic). */
@property (nonatomic, readonly) BOOL isWeak; /* The property is a weak reference (__weak). */
@property (nonatomic, readonly) NSString *customGetter; /* The property defines a custom getter selector name. */
@property (nonatomic, readonly) NSString *customSetter; /* The property defines a custom setter selector name. */
@property (nonatomic, readonly) CPPropertyInfoFlags flags;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *backedName;
@property (nonatomic, readonly) NSString *typeString;

- (instancetype)initWithPropertyName:(const char *)name andAttributes:(const char *)attributes;

@end
