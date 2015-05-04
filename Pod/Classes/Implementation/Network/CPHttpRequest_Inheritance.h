//
//  CPHttpRequest_Inheritance.h
//  CPHttpRequest_Inheritance
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

#import "CPHttpRequest.h"

typedef void (^CPHttpRequestCompletion)(CPHttpRequest *request, NSError *error, BOOL cancelled);

@interface CPHttpRequest (Inheritance)

- (void)openConnection;
- (void)releaseConnection;

- (void)startWithCompletionBlock:(CPHttpRequestCompletion)completion;
- (void)cancel;
- (void)cancelInLoop;

- (void)finish;
- (void)finishWithError:(NSError *)error;
- (void)finishWithErrorMessage:(NSString *)message andErrorCode:(NSInteger)code;

- (BOOL)isCanceled;

- (void)notifyFinishTarget;
- (void)notifyErrorTarget:(NSError *)error;
- (void)notifyCancelTarget;

@end
