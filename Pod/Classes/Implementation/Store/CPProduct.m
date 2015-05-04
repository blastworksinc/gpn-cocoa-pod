//
//  CPProduct.m
//  CPProduct
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

#import "CPProduct.h"

#import "CPCommon.h"

static NSString * const CPProductIdentifier  = @"identifier";
static NSString * const CPProductPrice       = @"price";
static NSString * const CPProductPriceLocale = @"price_locale";

@interface CPProduct () <NSCoding>

@end

@implementation CPProduct

- (id)initWithIdentifier:(NSString *)identifier price:(NSDecimalNumber *)price priceLocale:(NSLocale *)priceLocale
{
    self = [super init];
    if (self)
    {
        _identifier  = [identifier copy];
        _price       = [price copy];
        _priceLocale = [priceLocale copy];
    }
    return self;
}

- (id)initWithSKProduct:(SKProduct *)product
{
    NSString *identifier    = product.productIdentifier;
    NSDecimalNumber *price  = product.price;
    NSLocale *priceLocale   = product.priceLocale;
    
    return [self initWithIdentifier:identifier price:price priceLocale:priceLocale];
}


#pragma mark -
#pragma mark Class factory

+ (id)productWithIdentifier:(NSString *)identifier price:(NSDecimalNumber *)price priceLocale:(NSLocale *)priceLocale
{
    return [[self alloc] initWithIdentifier:identifier price:price priceLocale:priceLocale];
}

+ (id)productWithSKProduct:(SKProduct *)product
{
    return [[self alloc] initWithSKProduct:product];
}

#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        _identifier  = [[aDecoder decodeObjectForKey:CPProductIdentifier] copy];
        _price       = [[aDecoder decodeObjectForKey:CPProductPrice] copy];
        _priceLocale = [[aDecoder decodeObjectForKey:CPProductPriceLocale] copy];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_identifier  forKey:CPProductIdentifier];
    [aCoder encodeObject:_price       forKey:CPProductPrice];
    [aCoder encodeObject:_priceLocale forKey:CPProductPriceLocale];
}

#pragma mark -
#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"Product: identifier=%@, price=%@ locale=%@", _identifier, _price, _priceLocale.localeIdentifier];
}

#pragma mark -
#pragma mark Equality

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToProduct:other];
}

- (BOOL)isEqualToProduct:(CPProduct *)other {
    if (self == other)
        return YES;
    
    return [self.identifier isEqualToString:other.identifier] &&
           [self.price isEqual:other.price] &&
           [self.priceLocale isEqual:other.priceLocale];
}


@end
