//
//  CPHttpRequest.h
//  CPHttpRequest
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

#import "CPHttpRequestError.h"

@interface CPHttpRequest : NSObject

@property (nonatomic, readonly) NSString        * urlString;
@property (nonatomic, readonly) NSInteger         responseCode;
@property (nonatomic, readonly) NSData          * responseData;
@property (nonatomic, readonly) NSError         * error;
@property (nonatomic, readonly) NSDate          * startDate;
@property (nonatomic, readonly) NSTimeInterval    duration;

@property (nonatomic, strong) id  userData;
@property (nonatomic, assign) int tag;

+ (id)requestWithURLRequest:(NSURLRequest *)request;
- (id)initWithURLRequest:(NSURLRequest *)request;

@property (nonatomic, readonly) NSURLRequest * request;

@end
