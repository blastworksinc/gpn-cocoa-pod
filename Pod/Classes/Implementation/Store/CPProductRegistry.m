//
//  CPProductRegistry.m
//  CPProductRegistry
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

#import "CPProductRegistry.h"

#import "CPCommon.h"

@interface CPProductRegistry ()
{
    NSString            * _storagePath;
    NSMutableDictionary * _productsLookup;
}

@end

@implementation CPProductRegistry

- (id)initWithContentsOfFile:(NSString *)path
{
    self = [super init];
    if (self)
    {
        _storagePath = path;
        _productsLookup = [[NSMutableDictionary alloc] init];
        [self loadProductsFromFile:path];
    }
    return self;
}


#pragma mark -
#pragma mark Products

- (void)registerProduct:(CPProduct *)product
{
    CPLogDebug(CPTagPurchase, @"Register product: %@", product);
    CPSafeSetObject(_productsLookup, product, product.identifier);
}

- (CPProduct *)findProductWithIdentifier:(NSString *)identifier
{
    return [_productsLookup objectForKey:identifier];
}

#pragma mark -
#pragma mark Save/Load

- (BOOL)synchronize
{
    return [self saveProductsToFile:_storagePath];
}

- (BOOL)saveProductsToFile:(NSString *)file
{
    if (_productsLookup != nil)
    {
        return [NSKeyedArchiver archiveRootObject:_productsLookup toFile:file];
    }
    
    return NO;
}

- (BOOL)loadProductsFromFile:(NSString *)file
{
    [_productsLookup removeAllObjects];
    
    id rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:file];
    if ([rootObject isKindOfClass:[NSDictionary class]])
    {
        [_productsLookup addEntriesFromDictionary:rootObject];
        return YES;
    }
    
    return NO;
}

@end
