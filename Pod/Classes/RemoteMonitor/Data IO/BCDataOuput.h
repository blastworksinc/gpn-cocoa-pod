//
//  BCDataOuput.h
//  BCDataOuput
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

int BCWriteBool(NSOutputStream *stream, BOOL value);
int BCWriteByte(NSOutputStream *stream, int value);
int BCWriteShort(NSOutputStream *stream, int value);
int BCWriteChar(NSOutputStream *stream, int value);
int BCWriteInt(NSOutputStream *stream, int value);
int BCWriteFloat(NSOutputStream *stream, float value);
int BCWriteString(NSOutputStream *stream, NSString *value);
int BCWriteData(NSOutputStream *stream, NSData *data);
