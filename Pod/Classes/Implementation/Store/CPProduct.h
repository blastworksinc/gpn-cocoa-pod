//
//  CPProduct.h
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

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface CPProduct : NSObject

@property (nonatomic, readonly) NSString        * identifier;
@property (nonatomic, readonly) NSDecimalNumber * price;
@property (nonatomic, readonly) NSLocale        * priceLocale;

- (id)initWithIdentifier:(NSString *)identifier price:(NSDecimalNumber *)price priceLocale:(NSLocale *)priceLocale;
- (id)initWithSKProduct:(SKProduct *)product;

+ (id)productWithIdentifier:(NSString *)identifier price:(NSDecimalNumber *)price priceLocale:(NSLocale *)priceLocale;
+ (id)productWithSKProduct:(SKProduct *)product;

@end
