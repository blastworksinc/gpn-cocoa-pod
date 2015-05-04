//
//  CPConcurrentList.m
//  CPConcurrentList
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

#import "CPConcurrentList.h"

#import "CPCommon.h"

@interface CPConcurrentList ()
{
    NSMutableArray   * _array;
    NSOperationQueue * _queue;
    NSString         * _storagePath;
}

@end

@implementation CPConcurrentList

@synthesize array = _array;

- (id)init
{
    return [self initWithStoragePath:nil];
}

- (id)initWithStoragePath:(NSString *)path
{
    self = [super init];
    if (self)
    {
        _storagePath = path;
        
        _array = [[NSMutableArray alloc] init];
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1; // make it serial
        
        if (_storagePath)
        {
            [self loadFromFile:_storagePath];
        }
    }
    return self;
}

- (void)dealloc
{
    [_queue cancelAllOperations];
}

#pragma mark -
#pragma mark Save/Load

- (BOOL)loadFromFile:(NSString *)path
{
    CPAssert(path);
    
    NSArray *array = CPUnarchiveObjectWithFile(path, [NSArray class]);
    if (array)
    {
        [_array removeAllObjects];
        [_array addObjectsFromArray:array];
        return YES;
    }
    
    return NO;
}

- (BOOL)saveToFile:(NSString *)path
{
    CPAssert(path);
    
    return [NSKeyedArchiver archiveRootObject:_array toFile:path];
}

- (BOOL)synchronize
{
    CPAssert(_storagePath);
    return [self trySynchronize];
}

- (BOOL)trySynchronize
{
    if (_storagePath)
    {
        return [self saveToFile:_storagePath];
    }
    
    return NO;
}

#pragma mark -
#pragma mark Add/Remove objects

- (void)asyncAddObject:(id)object
{
    [self asyncAddObject:object withCallback:nil];
}

- (void)asyncAddObject:(id)object withCallback:(void (^)(CPConcurrentList *list))callback
{
    [_queue addOperationWithBlock:^{
        BOOL added = [self addObject:object];
        
        if (added && callback != nil)
            callback(self);
    }];
}

- (void)asyncRemoveObject:(id)object
{
    [self asyncRemoveObject:object withCallback:nil];
}

- (void)asyncRemoveObject:(id)object withCallback:(void (^)(CPConcurrentList *list))callback
{
    [_queue addOperationWithBlock:^{
        BOOL removed = [self removeObject:object];
        
        if (removed && callback != nil)
            callback(self);
    }];
}

- (BOOL)addObject:(id)object
{
    if (object != nil)
    {
        if (_allowsDuplicates || ![_array containsObject:object])
        {
            [_array addObject:object];
            [self trySynchronize];
            
            return YES;
        }
    }
    else
    {
        CPAssert(object);
    }
    
    return NO;
}

- (BOOL)removeObject:(id)object
{
    if (object != nil)
    {
        CPAssert([_array containsObject:object]);
        [_array removeObject:object];
        [self trySynchronize];
        
        return YES;
    }
    else
    {
        CPAssert(object);
    }
    
    return NO;
}

- (BOOL)containsObject:(id)object
{
    return object != nil && [_array containsObject:object];
}

#pragma mark -
#pragma mark Async dispatch

- (void)asyncDispatchBlock:(void (^)(CPConcurrentList *list))operationBlock
{
    [_queue addOperationWithBlock:^{
        if (operationBlock != nil)
            operationBlock(self);
    }];
}

- (void)waitUntilAllOperationsAreFinished
{
    [_queue waitUntilAllOperationsAreFinished];
}

- (void)cancelAllOperations
{
    [_queue cancelAllOperations];
}

#pragma mark -
#pragma mark Helpers

- (id)peekSync
{
    return _array.count > 0 ? [_array objectAtIndex:0] : nil;
}

- (NSInteger)count
{
    return _array.count;
}

@end
