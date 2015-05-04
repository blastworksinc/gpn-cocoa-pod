//
//  CPHttpJSonRequest.m
//  CPHttpJSonRequest
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

#import "CPHttpJSonRequest.h"
#import "CPHttpRequest_Inheritance.h"

#import "CPJSONUtils.h"
#import "CPDefines.h"

@implementation CPHttpJSonRequest

- (void)finish
{
    NSError *jsonError = NULL;
    
    id response = CPJSONObjectWithData(self.responseData, &jsonError);
    if (response == nil || [response isKindOfClass:[NSNull class]])
    {
        NSString *message = [[NSString alloc] initWithFormat:@"Unable to parse json: %@", [jsonError localizedDescription]];
        [self finishWithErrorMessage:message andErrorCode:CPHttpRequestErrorCodeJSonParserFailed];
    }
    else
    {     
        self.responseJson = response;
        [super finish];
    }
}

- (void)releaseConnection
{
    [super releaseConnection];
}

@end
