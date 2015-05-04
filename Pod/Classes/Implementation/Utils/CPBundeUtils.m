//
//  CPBundeUtils.m
//  CPBundeUtils
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

#import "CPBundleUtils.h"

static const NSString *CP_BUNDLE_NAME = @"PlacePlayAds.bundle";

static NSString *CPGetBundledPath(NSString *subpath)
{
    return [NSString stringWithFormat:@"%@/%@", CP_BUNDLE_NAME, subpath];
}

NSString *CPGetBundledResPath(NSString *name)
{
    return CPGetBundledPath([NSString stringWithFormat:@"Contents/Resources/%@", name]);
}

NSString *CPGetBundledImagePath(NSString *name)
{
    return CPGetBundledPath([NSString stringWithFormat:@"images/%@", name]);
}

UIImage *CPGetBundledImage(NSString *name)
{
    NSString *imagePath = CPGetBundledImagePath(name);
    return [UIImage imageNamed:imagePath];
}
