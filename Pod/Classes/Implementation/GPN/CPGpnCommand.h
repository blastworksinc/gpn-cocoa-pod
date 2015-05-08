//
//  CPGpnCommand.h
//  CPGpnCommand
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

#import "CPView.h"
#import "CPGpnView.h"

@interface CPGpnView (MRCommand)

@property (nonatomic, retain, readonly) CPGpnDisplayController * displayController;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

extern NSString * const CPGpnCommandErrorDomain;

@class CPGpnCommand;

typedef void (^CPGpnCommandCallback)(CPGpnCommand *command, NSError *error);

@interface CPGpnCommand : CPObject

@property (nonatomic, weak) CPGpnView          * view;
@property (nonatomic, copy)   NSString         * commandId;
@property (nonatomic, strong) NSDictionary     * parameters;
@property (nonatomic, readonly) NSString       * type;
@property (nonatomic, assign) BOOL cancelled;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface CPCancelCommand : CPGpnCommand
@end

@interface CPCloseCommand : CPGpnCommand
@end

@interface CPStoreCommand : CPGpnCommand
@end

@interface CPOpenURLCommand : CPGpnCommand
@end

@interface CPCompleteCommand : CPGpnCommand
@end

@interface CPVideoStartedCommand : CPGpnCommand
@end

@interface CPVideoCompletedCommand : CPGpnCommand
@end
