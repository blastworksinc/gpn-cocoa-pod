//
//  BCDataInput.h
//  BCDataInput
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

extern NSString * const BCReadErrorDomain;

BOOL BCReadBool(NSInputStream *stream, BOOL* ptr, NSError **errPtr);
BOOL BCReadByte(NSInputStream *stream, int* ptr, NSError **errPtr);
BOOL BCReadShort(NSInputStream *stream, int* ptr, NSError **errPtr);
BOOL BCReadChar(NSInputStream *stream, int* ptr, NSError **errPtr);
BOOL BCReadInt(NSInputStream *stream, int *ptr, NSError **errPtr);
BOOL BCReadFloat(NSInputStream *stream, float *ptr, NSError **errPtr);
BOOL BCReadString(NSInputStream *stream, NSString **ptr, NSError **errPtr);
BOOL BCReadBytes(NSInputStream *stream, NSString **ptr, NSUInteger length, NSError **errPtr);
BOOL BCReadData(NSInputStream *stream, NSData **ptr, NSError **errPtr);
