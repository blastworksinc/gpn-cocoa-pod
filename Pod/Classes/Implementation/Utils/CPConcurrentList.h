//
//  CPConcurrentList.h
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

#import <Foundation/Foundation.h>

@interface CPConcurrentList : NSObject

@property (nonatomic, readonly) NSMutableArray * array;
@property (nonatomic, readonly) NSInteger count;

@property (nonatomic, assign) BOOL allowsDuplicates;

- (id)init;
- (id)initWithStoragePath:(NSString *)path;

- (void)asyncAddObject:(id)object;
- (void)asyncAddObject:(id)object withCallback:(void (^)(CPConcurrentList *list))callback;

- (void)asyncRemoveObject:(id)object;
- (void)asyncRemoveObject:(id)object withCallback:(void (^)(CPConcurrentList *list))callback;

- (BOOL)addObject:(id)object;
- (BOOL)removeObject:(id)object;
- (BOOL)containsObject:(id)object;

- (void)asyncDispatchBlock:(void (^)(CPConcurrentList *list))operationBlock;

- (id)peekSync;

- (BOOL)synchronize;

- (void)waitUntilAllOperationsAreFinished;
- (void)cancelAllOperations;

@end
