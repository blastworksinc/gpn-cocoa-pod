//
//  CPPayment.m
//  CPPayment
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

#import "CPPayment.h"

#import "CPCommon.h"

static NSString * const CPTransactionIdentifier         = @"identifier";
static NSString * const CPTransactionProductIdentifier  = @"product";
static NSString * const CPTransactionQuantity           = @"quantity";
static NSString * const CPTransactionDate               = @"date";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat"

@interface CPPayment () <NSCoding>
@end

@implementation CPPayment

- (id)initWithIdentifier:(NSString *)identifier productIdentifier:(NSString *)productIdentifier quantity:(NSInteger)quantity date:(NSDate *)date
{
    self = [super init];
    if (self)
    {
        if (identifier == nil ||
            productIdentifier == nil ||
            date == nil)
        {
            self = nil;
            return nil;
        }
        
        _identifier        = identifier;
        _productIdentifier = productIdentifier;
        _date              = date;
        _quantity          = quantity;
    }
    return self;
}


#pragma mark -
#pragma mark Class factory

+ (id)paymentWithIdentifier:(NSString *)identifier productIdentifier:(NSString *)productIdentifier quantity:(NSInteger)quantity date:(NSDate *)date
{
    return [[self alloc] initWithIdentifier:identifier productIdentifier:productIdentifier quantity:quantity date:date];
}

#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        _identifier         = [aDecoder decodeObjectForKey:CPTransactionIdentifier];
        _productIdentifier  = [aDecoder decodeObjectForKey:CPTransactionProductIdentifier];
        _date               = [aDecoder decodeObjectForKey:CPTransactionDate];
        _quantity           = [aDecoder decodeIntegerForKey:CPTransactionQuantity];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_identifier          forKey:CPTransactionIdentifier];
    [aCoder encodeObject:_productIdentifier   forKey:CPTransactionProductIdentifier];
    [aCoder encodeObject:_date                forKey:CPTransactionDate];
    [aCoder encodeInteger:_quantity           forKey:CPTransactionQuantity];
}

#pragma mark -
#pragma mark Properties

- (NSTimeInterval)age
{
    return -_date.timeIntervalSinceNow;
}

#pragma mark -
#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"Payment: identifier=%@ product=%@, date=%@, quantity=%ld", _identifier, _productIdentifier, _date, _quantity];
}

#pragma mark -
#pragma mark Equality

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToPayment:other];
}

- (BOOL)isEqualToPayment:(CPPayment *)other {
    if (self == other)
        return YES;
    
    return [self.identifier isEqualToString:other.identifier] &&
           [self.productIdentifier isEqualToString:other.productIdentifier] &&
           [self.date isEqualToDate:other.date] &&
            self.quantity == other.quantity;
}

@end

#pragma clang diagnostic pop
