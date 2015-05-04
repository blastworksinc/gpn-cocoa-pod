//
//  CPFileUtils.m
//  CPFileUtils
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

#import "CPFileUtils.h"

#import "CPCommon.h"

#pragma mark -
#pragma mark Helpers

static NSURL * CPGetDirectoryURL(NSSearchPathDirectory directory)
{
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:directory inDomains:NSUserDomainMask];
    return URLs.count > 0 ? [URLs objectAtIndex:0] : nil;
}

static NSString * CPGetDirectoryPath(NSSearchPathDirectory directory)
{
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    return pathArray.count > 0 ? [pathArray objectAtIndex:0] : nil;
}

#pragma mark -
#pragma mark Public

NSURL* CPGetURLForAppSupportFile(NSString *subpath)
{
    NSURL *baseURL = CPGetDirectoryURL(NSApplicationSupportDirectory);
    return baseURL != nil ? [NSURL URLWithString:subpath relativeToURL:baseURL] : nil;
}

NSString *CPGetAppSupportDirectoryPath(BOOL createIfNecessary)
{
    NSString *path = CPGetDirectoryPath(NSApplicationSupportDirectory);
    if (createIfNecessary && !CPDirExists(path))
    {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil)
        {
            CPLogError(CPTagCommon, @"Can't create directory: %@\n%@", path, error);
        }
    }
    
    return path;
}

NSString *CPGetAppSupportDirectorySubpath(NSString *path, BOOL createIfNecessary)
{
    NSString *basePath = CPGetAppSupportDirectoryPath(createIfNecessary);
    return [basePath stringByAppendingPathComponent:path];
}

BOOL CPFileExists(NSString *path)
{
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

BOOL CPDirExists(NSString *path)
{
    BOOL isDirectory = NO;
    return [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory;
}
