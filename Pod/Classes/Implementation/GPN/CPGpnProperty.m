//
//  CPGpnProperty.m
//  CPGpnProperty
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

#import "CPGpnProperty.h"
#import "CPCommon.h"

@implementation CPGpnProperty

- (NSString *)description {
    return @"";  
}

- (NSString *)jsonString {
    return @"{}";
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CPGpnStateProperty

@synthesize state = _state;

+ (CPGpnStateProperty *)propertyWithState:(CPGpnViewState)state {
    CPGpnStateProperty *property = [[self alloc] init];
    property.state = state;
    return property;
}

- (NSString *)description {
    NSString *stateString;
    switch (_state) {
        case CPGpnViewStateHidden:      stateString = @"hidden"; break;
        case CPGpnViewStateDefault:     stateString = @"default"; break;
        case CPGpnViewStatePresenting:  stateString = @"presenting"; break;
        case CPGpnViewStatePresented:   stateString = @"presented"; break;
        default:                        stateString = @"loading"; break;
    }
    return [NSString stringWithFormat:@"state: '%@'", stateString];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CPGpnScreenSizeProperty

@synthesize screenSize = _screenSize;

+ (CPGpnScreenSizeProperty *)propertyWithSize:(CGSize)size {
    CPGpnScreenSizeProperty *property = [[self alloc] init];
    property.screenSize = size;
    return property;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"screen_size: {width: %f, height: %f}", 
            _screenSize.width, 
            _screenSize.height];  
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CPGpnNetworkReachabilityProperty

@synthesize state = _state;

+ (CPGpnNetworkReachabilityProperty *)propertyWithState:(NSString *)state {
    CPGpnNetworkReachabilityProperty *property = [[self alloc] init];
    property.state = state;
    return property;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"connection_type: '%@'", _state];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CPGpnParamsProperty

@synthesize properties = _properties;

+ (id)propertyWithParams:(NSDictionary *)properties
{
    CPGpnParamsProperty *property = [[self alloc] init];
    property.properties = properties;
    return property;
}


- (NSString *)description {
    NSError *error = nil;
    
    NSString *jsonString = CPStringWithJSONObject(_properties, &error);
    if (error == nil)
    {
        return [NSString stringWithFormat:@"properties: %@", jsonString];
    }
    
    return @"properties: ''";
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CPGpnFreeMemoryProperty

@synthesize freeMegabytes = _freeMegabytes;

- (id)initWithFreeMegabytes:(float)freeMegabytes
{
    self = [super init];
    if (self)
    {
        _freeMegabytes = freeMegabytes;
    }
    return self;
}

+ (id)propertyWithFreeMegabytes:(float)freeMegabytes
{
    return [[self alloc] initWithFreeMegabytes:freeMegabytes];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"system: { free_memory: '%.1f'}", _freeMegabytes];
}

@end
