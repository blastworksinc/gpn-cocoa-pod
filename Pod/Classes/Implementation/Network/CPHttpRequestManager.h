//
//  CPHttpRequestManager.h
//  CPHttpRequestManager
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

#import "CPHttpRequest.h"

@interface CPHttpRequestManager : NSObject

@property (nonatomic, readonly) NSArray * requests;
@property (nonatomic, readonly) NSInteger requestCount;

- (void)queueRequest:(CPHttpRequest *)request completion:(void(^)(CPHttpRequest *request, NSError *error, BOOL cancelled))completion;
- (void)cancelAll;

@end
