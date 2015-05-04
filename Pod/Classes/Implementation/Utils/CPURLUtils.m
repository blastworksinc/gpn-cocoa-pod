//
//  CPURLUtils.m
//  CPURLUtils
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

#import "CPURLUtils.h"

#import "CPDefines.h"

NSString * CPCreateQueryString(NSDictionary *parameters, NSStringEncoding stringEncoding) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (id key in parameters) {
        id value = [parameters objectForKey:key];
        [mutablePairs addObject:CPCreateURLEncodedString(key, value, stringEncoding)];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSString * CPCreateURLEncodedString(id field, id value, NSStringEncoding stringEncoding) {
    if (!value || [value isEqual:[NSNull null]]) {
        return CPCreatePercentEscapedString([field description], stringEncoding);
    } else {
        return [NSString stringWithFormat:@"%@=%@",
                CPCreatePercentEscapedString([field description], stringEncoding),
                CPCreatePercentEscapedString([value description], stringEncoding)];
    }
}

NSString * CPCreatePercentEscapedString(NSString *string, NSStringEncoding encoding) {
    static NSString * const kAFCharactersToBeEscaped = @":/#?&@%+~ ;=$,<>^`\\[]{}|\"";
    static NSString * const kAFCharactersToLeaveUnescaped = NULL;
    
    return (__CP_BRIDGE_TRANSFER  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__CP_BRIDGE CFStringRef)string, (__CP_BRIDGE CFStringRef)kAFCharactersToLeaveUnescaped, (__CP_BRIDGE CFStringRef)kAFCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding));
}
