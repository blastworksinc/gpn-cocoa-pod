//
//  NSDictionary_Types.h
//  NSDictionary_Types
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

extern NSInteger CPIntegerForKey(NSDictionary *dict, id key);
extern BOOL CPBooleanForKey(NSDictionary *dict, id key);
extern float CPFloatForKey(NSDictionary *dict, id key);
extern double CPDoubleForKey(NSDictionary *dict, id key);
extern NSString * CPStringForKey(NSDictionary *dict, id key);
extern NSDictionary * CPDictionaryForKey(NSDictionary *dict, id key);
extern NSURL * CPURLForKey(NSDictionary *dict, id key);
extern id CPObjectForKeyAndClass(NSDictionary *dict, id key, Class clss);
