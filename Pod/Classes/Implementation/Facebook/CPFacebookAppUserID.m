//
//  CPFacebookAppUserID.m
//  CPFacebookAppUserID
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

#import "CPFacebookAppUserID.h"

#import "CPCommon.h"

#define kClassFBSDKAppEvents @"FBSDKAppEvents"
#define kCPFacebookErrorDomain @"CPFacebookErrorDomain"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

@implementation CPFacebookAppUserID

+ (void)requestWithCompletionHandler:(void(^)(NSString *userId, NSError *error))completion
{
    // check if class exists
    Class appEventsClass = NSClassFromString(kClassFBSDKAppEvents);
    if (!appEventsClass)
    {
        if (completion)
        {
            NSError *error = [self errorWithCode:100 message:[NSString stringWithFormat:@"'%@' class not found", kClassFBSDKAppEvents]];
            completion(nil, error);
        }
        
        return;
    }
    
    // check if class responds to selector
    SEL requestForCustomAudienceThirdPartyIDWithAccessToken = @selector(requestForCustomAudienceThirdPartyIDWithAccessToken:);
    if (![appEventsClass respondsToSelector:requestForCustomAudienceThirdPartyIDWithAccessToken])
    {
        if (completion)
        {
            NSString *selectorName = NSStringFromSelector(requestForCustomAudienceThirdPartyIDWithAccessToken);
            NSError *error = [self errorWithCode:200 message:[NSString stringWithFormat:@"'%@' selector not found in class %@", selectorName, NSStringFromClass(appEventsClass)]];
            completion(nil, error);
        }
        
        return;
    }
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    id requestObject = [appEventsClass performSelector:requestForCustomAudienceThirdPartyIDWithAccessToken withObject:nil];
    if (!requestObject)
    {
        if (completion)
        {
            NSError *error = [self errorWithCode:300 message:@"request object is nil"];
            completion(nil, error);
        }
        
        return;
    }
    
    SEL startWithCompletionHandlerSelector = @selector(startWithCompletionHandler:);
    if (![requestObject respondsToSelector:startWithCompletionHandlerSelector])
    {
        if (completion)
        {
            NSString *selectorName = NSStringFromSelector(startWithCompletionHandlerSelector);
            NSError *error = [self errorWithCode:400 message:[NSString stringWithFormat:@"'%@' selector not found in class %@", selectorName, NSStringFromClass([requestObject class])]];
            completion(nil, error);
        }
        
        return;
    }
    
    [requestObject performSelector:startWithCompletionHandlerSelector withObject:^(id connection, id result, NSError *error)
    {
        // check for the error
        if (error)
        {
            if (completion)
            {
                completion(nil, [self errorWithCode:500 message:[error localizedDescription]]);
            }
            
            return;
        }
        
        // check if result is present
        if (!result)
        {
            if (completion)
            {
                completion(nil, [self errorWithCode:600 message:@"result is nil"]);
            }
            
            return;
        }
        
        SEL objectForKeySelector = @selector(objectForKey:);
        if (![result respondsToSelector:objectForKeySelector])
        {
            if (completion)
            {
                NSString *selectorName = NSStringFromSelector(objectForKeySelector);
                NSError *error = [self errorWithCode:700
                                             message:[NSString stringWithFormat:@"'%@' selector not found in class %@", selectorName, NSStringFromClass([requestObject class])]];
                completion(nil, error);
            }
            
            return;
        }
        
        id value = [result objectForKey:@"custom_audience_third_party_id"];
        NSString *userId = [value isKindOfClass:[NSString class]] ? (NSString *)value : nil;
        
        if (completion)
        {
            completion(userId, nil);
        }
    }];
    
    #pragma clang diagnostic pop
}

+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message
{
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey : (message ? message : @"")
    };
    return [NSError errorWithDomain:kCPFacebookErrorDomain code:code userInfo:userInfo];
}

#pragma clang diagnostic pop

@end
