//
//  CPStringUtils.m
//  CPStringUtils
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

#import <CommonCrypto/CommonDigest.h>

#import "CPCommon.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"
#pragma clang diagnostic ignored "-Wunreachable-code"

static NSScanner* create_scanner(NSString *string)
{
    if (string)
    {
        NSScanner *scanner = [[NSScanner alloc] initWithString:string];
        scanner.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        scanner.charactersToBeSkipped = nil;
        return scanner;
    }
    
    return nil;
}

BOOL CPStringParseBool(NSString *string, BOOL *outValue)
{
    if (string && outValue)
    {
        if ([string isEqualToString:@"1"])
        {
            *outValue = YES;
            return YES;
        }
        
        if ([string isEqualToString:@"0"])
        {
            *outValue = NO;
            return YES;
        }
        
        NSString *noCaseString = [string lowercaseString];
        
        if ([noCaseString isEqualToString:@"yes"] ||
            [noCaseString isEqualToString:@"true"])
        {
            *outValue = YES;
            return YES;
        }
        
        if ([noCaseString isEqualToString:@"no"] ||
            [noCaseString isEqualToString:@"false"])
        {
            *outValue = NO;
            return YES;
        }
    }
    
    return NO;
}

BOOL CPStringParseInteger(NSString *string, NSInteger *outValue)
{
    if (outValue != NULL)
    {
        NSScanner *scanner = create_scanner(string);
        return [scanner scanInteger:outValue] && scanner.atEnd;
    }
    return NO;
}

BOOL CPStringParseFloat(NSString *string, float *outValue)
{
    if (outValue != NULL)
    {
        NSScanner *scanner = create_scanner(string);
        return [scanner scanFloat:outValue] && scanner.atEnd;
    }
    return NO;
}

NSString *CPStringFormat(NSString *format,...)
{
    va_list ap;
    va_start(ap, format);
    NSString *string = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);

    return string;
}

NSString *CPUnescapeString(NSString *str)
{
    NSString *result = [str stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    return [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

NSString* CPCalculateMD5(NSString *string)
{
    if (string != nil)
    {
        const char* cString = [string UTF8String];
        unsigned char result [CC_MD5_DIGEST_LENGTH];
        CC_MD5( cString, strlen(cString), result );
        
        return [NSString
                stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                result[0], result[1],
                result[2], result[3],
                result[4], result[5],
                result[6], result[7],
                result[8], result[9],
                result[10], result[11],
                result[12], result[13],
                result[14], result[15]
                ];
    }
    
    return nil;
}


NSString *CPRFC3339StringForDate(NSDate *date)
{
    if (date == nil) {
        return nil;
    }
    
    NSDateFormatter *dateFormatter = nil;
    NSDateFormatter *timezoneFormatter = nil;
    
    CPTRY
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";
        dateFormatter.timeZone = [NSTimeZone localTimeZone];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        NSString *dateString = [dateFormatter stringFromDate:date];
        
        timezoneFormatter = [[NSDateFormatter alloc] init];
        timezoneFormatter.dateFormat = @"Z";
        timezoneFormatter.timeZone = [NSTimeZone localTimeZone];
        NSString *timezone = [timezoneFormatter stringFromDate:date];
        NSString *timezoneFormatted = [NSString stringWithFormat:@"%@:%@", [timezone substringToIndex:3], [timezone substringFromIndex:3]];
        
        return [NSString stringWithFormat:@"%@%@", dateString, timezoneFormatted];
    }
    CPCATCH(e)
    {
        CPLogError(CPTagCommon, @"Error formatting date: %@", e);
    }
}

#pragma clang diagnostic pop