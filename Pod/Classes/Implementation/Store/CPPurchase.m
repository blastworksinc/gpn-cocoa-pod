//
//  CPPurchase.m
//  CPPurchase
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

#import "CPPurchase.h"

#import "CPCommon.h"

#if CP_DEBUG_PURCHASE

BOOL CPPurchaseDebugFlagShouldFailTrackingRequest       = NO;
BOOL CPPurchaseDebugFlagShouldSucceedTrackingRequest    = NO;
BOOL CPPurchaseDebugFlagShouldFailProductsRequest       = NO;
BOOL CPPurchaseDebugFlagShouldOverrideCacheAge          = NO;
BOOL CPPurchaseDebugFlagShouldOverrideCacheSize         = NO;

NSTimeInterval CPPurchaseDebugDelayTrackingRequest      = 0.0;
NSTimeInterval CPPurchaseDebugDelayProductsRequest      = 0.0;

NSInteger CPPurchaseDebugOverridenCacheAge              = 0;
NSInteger CPPurchaseDebugOverridenCacheSize             = 0;

#endif

static NSString * const CPPurchaseKeyProduct = @"product";
static NSString * const CPPurchaseKeyPayment = @"payment";

@interface CPPurchase () <NSCoding>
@end

@implementation CPPurchase

- (id)initWithProduct:(CPProduct *)product andPayment:(CPPayment *)payment
{
    self = [super init];
    if (self)
    {
        _product = product;
        _payment = payment;
    }
    
    return self;
}


#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        _product = [aDecoder decodeObjectForKey:CPPurchaseKeyProduct];
        _payment = [aDecoder decodeObjectForKey:CPPurchaseKeyPayment];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_product forKey:CPPurchaseKeyProduct];
    [aCoder encodeObject:_payment forKey:CPPurchaseKeyPayment];
}

#pragma mark -
#pragma mark Class factory

+ (id)purchaseWithProduct:(CPProduct *)product andPayment:(CPPayment *)payment
{
    return [[self alloc] initWithProduct:product andPayment:payment];
}

#pragma mark -
#pragma mark Properties

- (NSDate *)date
{
    return _payment.date;
}

- (NSTimeInterval)age
{
    return _payment.age;
}

#pragma mark -
#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"Transaction: [%@, %@]", _product, _payment];
}

#pragma mark -
#pragma mark Equality

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToPurchase:other];
}

- (BOOL)isEqualToPurchase:(CPPurchase *)other {
    if (self == other)
        return YES;
    
    return [self.payment isEqual:other.payment] &&
           [self.product isEqual:other.product];
}

@end
