//
//  CPCoderUtils.m
//  CPCoderUtils
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

#import "CPCoderUtils.h"

#import "CPCommon.h"

id CPUnarchiveObjectWithData(NSData *data, Class aClass)
{
    CPAssert(data);
    
    CPTRY
    {
        if (data)
        {
            id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            if ([object isKindOfClass:aClass])
            {
                return object;
            }
        }
    }
    CPCATCH(e)
    {
        CPLogDebug(CPTagCommon, @"Can't unarchive object: %@", e);
    }
    
    return nil;
}

id CPUnarchiveObjectWithFile(NSString *path, Class aClass)
{
    CPAssert(path);
    
    if (path)
    {
        NSData *data = [[NSData alloc] initWithContentsOfFile:path];
        if (data)
        {
            return CPUnarchiveObjectWithData(data, aClass);
        }
        
        CPLogDebug(CPTagCommon, @"Can't read data from path: %@", path);
    }
    
    return nil;
}

BOOL CPArchiveObject(id rootObject, NSString *path)
{
    CPAssert(rootObject);
    CPAssert(path);
    
    if (rootObject != nil && path != nil)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
        
        CPTRY
        {
            return [NSKeyedArchiver archiveRootObject:rootObject toFile:path];
        }
        CPCATCH(e)
        {
            CPLogDebug(CPTagCommon, @"Can't save data to path: %@", e);
        }
        
#pragma clang diagnostic pop
    }
    
    return NO;
}
