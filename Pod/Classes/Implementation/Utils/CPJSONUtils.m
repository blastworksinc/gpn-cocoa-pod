//
//  CPJSONUtils.m
//  CPJSONUtils
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

#import "CPJSONUtils.h"

#import "CPCommon.h"

NSData * CPDataWithJSONObject(id object, NSError **outError)
{
    // iOS 4.3 check
    if (!CP_CLASS_AVAILABLE(NSJSONSerialization))
    {
        return nil;
    }
    
    if ([NSJSONSerialization isValidJSONObject:object])
    {
        return [NSJSONSerialization dataWithJSONObject:object options:0 error:outError];
    }
    
    CPAssert(false);
    return nil;
}

NSString * CPStringWithJSONObject(id object, NSError **outError)
{
    NSData *data = CPDataWithJSONObject(object, outError);
    if (data != nil)
    {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

extern id CPJSONObjectWithData(NSData *data, NSError **outError)
{
    // iOS 4.3 check
    if (!CP_CLASS_AVAILABLE(NSJSONSerialization))
    {
        return nil;
    }
    
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:outError];
}
