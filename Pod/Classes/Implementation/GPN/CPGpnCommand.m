//
//  CPGpnCommand.m
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

#import "CPCommon.h"

#import "CPGpnCommand.h"
#import "CPGpnView_Controllers.h"
#import "CPGpnDisplayController.h"

#import "CPStoreProductController.h"

NSString * const CPGpnCommandErrorDomain = @"CPGpnCommandErrorDomain";

static NSString * const CPGpnCancelCommandId = @"commandId";

@interface CPGpnView (Commands)

- (BOOL)tryCancelCommandWithId:(NSString *)commandId;
- (void)openSpecialUrl:(NSURL *)url;

@end

@interface CPGpnCommand ()

@property (nonatomic, copy) CPGpnCommandCallback callback;

- (void)finish;
- (void)finishWithError:(NSError *)error;
- (void)finishWithErrorMessage:(NSString *)message;

@end

@implementation CPGpnCommand

+ (NSMutableDictionary *)sharedCommandClassMap
{
    static NSMutableDictionary *sharedMap = nil;
    @synchronized(self) {
        if (!sharedMap) sharedMap = [[NSMutableDictionary alloc] init];
    }
    return sharedMap;
}

+ (void)registerCommand:(Class)commandClass
{
    NSMutableDictionary *map = [self sharedCommandClassMap];
    @synchronized(self) {
        [map setValue:commandClass forKey:[commandClass commandType]];
    }
}

+ (NSString *)commandType
{
    return @"BASE_CMD_TYPE";
}

+ (Class)commandClassForString:(NSString *)string
{
    NSMutableDictionary *map = [self sharedCommandClassMap];
    @synchronized(self)
    {
        return [map objectForKey:string];
    }
}

+ (id)commandForString:(NSString *)string
{
    Class commandClass = [self commandClassForString:string];
    return [[commandClass alloc] init];
}


- (void)execute
{
    [self finish];
}

- (void)finish
{
    [self finishWithError:nil];
}

- (void)finishWithError:(NSError *)error
{
    if (_callback) {
        _callback(self, error);
    }
}
    
- (void)finishWithErrorMessage:(NSString *)message
{
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey : message
    };
    
    [self finishWithError:[NSError errorWithDomain:CPGpnCommandErrorDomain code:0 userInfo:userInfo]];
}

- (void)cancel
{
    if (!_cancelled) {
        _cancelled = YES;
        [self finish];
    }
}

- (CGFloat)floatFromParametersForKey:(NSString *)key
{
    return [self floatFromParametersForKey:key withDefault:0.0];
}

- (CGFloat)floatFromParametersForKey:(NSString *)key withDefault:(CGFloat)defaultValue
{
    NSString *stringValue = [self.parameters valueForKey:key];
    return stringValue ? [stringValue floatValue] : defaultValue;
}

- (BOOL)boolFromParametersForKey:(NSString *)key
{
    NSString *stringValue = [self.parameters valueForKey:key];
    return [stringValue isEqualToString:@"true"];
}

- (int)intFromParametersForKey:(NSString *)key
{
    NSString *stringValue = [self.parameters valueForKey:key];
    return stringValue ? [stringValue intValue] : -1;
}

- (NSString *)stringFromParametersForKey:(NSString *)key
{
    NSString *value = [self.parameters objectForKey:key];
    if (!value || [value isEqual:[NSNull null]]) return nil;
    
    value = [value stringByTrimmingCharactersInSet:
             [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!value || [value isEqual:[NSNull null]] || value.length == 0) return nil;
    
    return value;
}

- (NSString *)type
{
    return [[self class] commandType];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CPCancelCommand

+ (void)load
{
    [CPGpnCommand registerCommand:self];
}

+ (NSString *)commandType
{
    return @"cancel";
}

- (void)execute
{
    NSString *commandId = [self stringFromParametersForKey:CPGpnCancelCommandId];
    if (commandId == nil) {
        CPLogError(CPTagCommands, @"Missing required param: '%@'", CPGpnCancelCommandId);
        [self finishWithErrorMessage:[NSString stringWithFormat:@"Missing required param: '%@'", CPGpnCancelCommandId]];
    }
    else {
        [self.view tryCancelCommandWithId:commandId];
        [super execute];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CPCloseCommand

+ (void)load
{
    [CPGpnCommand registerCommand:self];
}

+ (NSString *)commandType
{
    return @"close";
}

- (void)execute
{
    [self.view.displayController closeDelayed]; // 'close' will cancel all commands, but we need to wait til this command finishes
    [super execute];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface CPStoreCommand () <CPStoreProductControllerDelegate> {
    CPStoreProductController * _storeProductController;
}

@property (nonatomic, strong) CPStoreProductController * storeProductController;

@end

@implementation CPStoreCommand

@synthesize storeProductController = _storeProductController;

+ (void)load
{
    [CPGpnCommand registerCommand:self];
}

+ (NSString *)commandType
{
    return @"itunes";
}

- (void)dealloc
{
    self.storeProductController = nil;
}

- (void)execute
{
    NSString *appId = [self stringFromParametersForKey:@"app_id"];
    
    if (CPAvailabilitySystemVersionAvailable(__IPHONE_6_0)) {
        self.storeProductController = [[CPStoreProductController alloc] init];
        [_storeProductController setDelegate:self];
        [_storeProductController presentWithAppId:appId];
    }
    else {
        CPAssert(CPAvailabilitySystemVersionAvailable(__IPHONE_6_0));
        [self finish]; // TODO: finish with error
    }
}

- (void)setStoreProductController:(CPStoreProductController *)storeProductController
{
    if (_storeProductController != storeProductController) {
        _storeProductController.delegate = nil;
        _storeProductController = storeProductController;
    }
}

#pragma mark -
#pragma mark CPStoreProductControllerDelegate

- (void)productControllerDidFinish:(CPStoreProductController *)viewController
{
    [self finish];
}

- (void)productController:(CPStoreProductController *)viewController didFailError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:[error localizedDescription]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
    [self finishWithError:error];
}

@end

@implementation CPOpenURLCommand
    
+ (void)load
{
    [CPGpnCommand registerCommand:self];
}
    
+ (NSString *)commandType
{
    return @"openurl";
}
    
- (void)execute
{
    NSString *urlString = [self stringFromParametersForKey:@"url"];
    if (!urlString)
    {
        [self finishWithErrorMessage:[NSString stringWithFormat:@"Missing required param: url"]];
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:url])
    {
        [self.view openSpecialUrl:url];
        [self finish];
    }
    else
    {
        [self finishWithErrorMessage:[NSString stringWithFormat:@"Unable to open an external url: %@", urlString]];
    }
}
    
@end

@implementation CPCompleteCommand

static NSString * const kParamIncludesPosition = @"position_includes";
static NSString * const kParamExcludesPosition = @"position_excludes";

+ (void)load
{
    [CPGpnCommand registerCommand:self];
}

+ (NSString *)commandType
{
    return @"complete";
}

- (void)execute
{
    [self updatePositions];
    
    [self.view adDidLoad];
    [self finish];
}

- (void)updatePositions
{
    CPInterstitialAdView *interstitialView = [CrossPromotion sharedInstance].interstitialAdView;
    CPAssert(interstitialView != nil);
    
    NSString *includes = [self stringFromParametersForKey:kParamIncludesPosition];
    if (includes != nil)
    {
        CPLogDebug(CPTagCommands, @"Includes positions: %@", includes);
        interstitialView.includesPositions = [self positionsFromString:includes];
    }
    else
    {
        interstitialView.includesPositions = nil;
    }
    
    NSString *excludes = [self stringFromParametersForKey:kParamExcludesPosition];
    if (excludes != nil)
    {
        CPLogDebug(CPTagCommands, @"Excludes positions: %@", excludes);
        interstitialView.excludesPositions = [self positionsFromString:excludes];
    }
    else
    {
        interstitialView.excludesPositions = nil;
    }
}

- (NSArray *)positionsFromString:(NSString *)string
{
    return [string componentsSeparatedByString:@","];
}

@end

@implementation CPVideoStartedCommand

+ (void)load
{
    [CPGpnCommand registerCommand:self];
}

+ (NSString *)commandType
{
    return @"videoStarted";
}

- (void)execute
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CrossPromotionVideoStartedNotification object:nil];
    [self finish];
}

@end

@implementation CPVideoCompletedCommand

+ (void)load
{
    [CPGpnCommand registerCommand:self];
}

+ (NSString *)commandType
{
    return @"videoComplete";
}

- (void)execute
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CrossPromotionVideoCompletedNotification object:nil];
    [self finish];
}

@end
