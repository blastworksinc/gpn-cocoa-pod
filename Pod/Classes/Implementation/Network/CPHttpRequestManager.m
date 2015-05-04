//
//  CPHttpRequestManager.m
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

#import "CPHttpRequestManager.h"
#import "CPHttpRequest_Inheritance.h"

#import "CPDebug.h"

@interface CPHttpRequestManager ()
{
    NSMutableArray * _requests;
}

@end

@implementation CPHttpRequestManager

- (id)init
{
    self = [super init];
    if (self)
    {
        _requests = [NSMutableArray array];
    }
    return self;
}


- (void)queueRequest:(CPHttpRequest *)request completion:(void (^)(CPHttpRequest *request, NSError *error, BOOL cancelled))completion
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_requests addObject:request];
        
        [request startWithCompletionBlock:^(CPHttpRequest *req, NSError *error, BOOL cancelled) {
            CPHttpRequest *local = req; // maintain a strong reference
            
            [_requests removeObject:req];
            completion(local, error, cancelled);
            
            
        }];
    });
}

- (void)cancelAll
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (CPHttpRequest *request in _requests) {
            [request cancelInLoop];
        }
        [_requests removeAllObjects];
    });
}

#pragma mark -
#pragma mark Properties

- (NSInteger)requestCount
{
    return _requests.count;
}

@end
