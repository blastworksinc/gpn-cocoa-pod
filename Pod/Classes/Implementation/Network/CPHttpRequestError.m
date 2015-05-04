//
//  CPHttpRequestError.m
//  CPHttpRequestError
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

#import "CPHttpRequestError.h"

#import "CPHttpRequest.h"

#define kPAHttpRequestErrorDomain @"CPHttpRequestErrorDomain"

@implementation CPHttpRequestError

@synthesize request;

- (id)initWithRequest:(CPHttpRequest *)aRequest errorCode:(NSInteger)code andMessage:(NSString *)message
{
    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:message, @"NSLocalizedDescriptionKey", nil];
    self = [super initWithDomain:kPAHttpRequestErrorDomain code:code userInfo:info];
    
    if (self)
    {
        request = aRequest;
    }
    
    return self;
}


- (NSInteger)responseCode
{
    return request.responseCode;
}

@end
