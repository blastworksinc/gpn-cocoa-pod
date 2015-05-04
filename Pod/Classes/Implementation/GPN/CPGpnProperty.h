//
//  CPGpnProperty.h
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

#import <UIKit/UIKit.h>

#import "CPObject.h"

typedef enum {
    CPGpnViewStateHidden = 0,
    CPGpnViewStateDefault = 1,
    CPGpnViewStatePresenting = 3,
    CPGpnViewStatePresented = 4
} CPGpnViewState;

@interface CPGpnProperty : CPObject

- (NSString *)description;
- (NSString *)jsonString;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface CPGpnStateProperty : CPGpnProperty {
    CPGpnViewState _state;
}

@property (nonatomic, assign) CPGpnViewState state;

+ (CPGpnStateProperty *)propertyWithState:(CPGpnViewState)state;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface CPGpnScreenSizeProperty : CPGpnProperty {
    CGSize _screenSize;
}

@property (nonatomic, assign) CGSize screenSize;

+ (CPGpnScreenSizeProperty *)propertyWithSize:(CGSize)size;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface CPGpnNetworkReachabilityProperty : CPGpnProperty {
    NSString * _state;
}

@property (nonatomic, copy) NSString * state;

+ (CPGpnNetworkReachabilityProperty *)propertyWithState:(NSString *)state;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface CPGpnParamsProperty : CPGpnProperty {
    NSDictionary * _properties;
}

@property (nonatomic, strong) NSDictionary * properties;

+ (id)propertyWithParams:(NSDictionary *)properties;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface CPGpnFreeMemoryProperty : CPGpnProperty

@property (nonatomic, readonly) float freeMegabytes;

+ (id)propertyWithFreeMegabytes:(float)freeMegabytes;

@end
