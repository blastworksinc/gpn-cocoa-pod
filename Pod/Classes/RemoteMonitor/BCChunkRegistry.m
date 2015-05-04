//
//  BCChunkRegistry.m
//  BCChunkRegistry
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

#import "BCChunkRegistry.h"

#import "BCChunk.h"

static BCChunkRegistry * _sharedInstance;

@interface BCChunkRegistry ()
{
    NSMutableDictionary * _lookup;
}

@end

@implementation BCChunkRegistry

- (id)init
{
    self = [super init];
    if (self)
    {
        _lookup = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)registerChunkName:(NSString *)name toClass:(Class)chunkClass
{
    [_lookup setObject:chunkClass forKey:name];
}

- (BCChunk *)chunkForName:(NSString *)name
{
    Class chunkClass = [_lookup objectForKey:name];
    if (chunkClass != nil)
    {
        return [[chunkClass alloc] init];
    }
    
    return nil;
}

+ (BCChunkRegistry *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[BCChunkRegistry alloc] init];
    });
    
    return _sharedInstance;
}

@end
