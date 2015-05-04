//
//  CrossPromotion.m
//  CrossPromotion
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

#import <StoreKit/StoreKit.h>

#import "CrossPromotion_Internal.h"

#import "CPCommon.h"
#import "GTMStackTrace.h"

BOOL CPConfigOverrideWindowLevel = NO;
BOOL CPConfigNeedsTransformForViewInWindow = YES;

static CrossPromotion * sharedInstance;

NSString * const CrossPromotionVideoStartedNotification         = @"com.gamehouse.VideoStartedNotification";
NSString * const CrossPromotionVideoCompletedNotification       = @"com.gamehouse.VideoCompletedNotification";
NSString * const CrossPromotionSettingsDidUpdateNotification    = @"com.gamehouse.SettingsDidUpdateNotification";

NSString * const CrossPromotionSettingsDidUpdateNotificationKeySettings = @"Settings";

static NSString * const CPDebuggerURLScheme                     = @"gpndebugger";
static NSString * const CPDebuggerTestURL                       = @"gpndebugger://test";

static NSString * _serverDefaultURL;

static NSUncaughtExceptionHandler * _oldUncaughtExceptionHandler;
static BOOL                         _isCatchingExceptions;

static void CPUncaughtExceptionHandler(NSException *e);
static void CPDebugSetCatchUnhandledExceptions(BOOL flag);

@interface CrossPromotion ()
{
    NSString             * _appId;
    
    CPSettings           * _settings;
    
    CPServerApi          * _serverApi;
    CPInterstitialAdView * _interstitialAdView;
    
    CPPurchaseTracker    * _purchaseTracker;
    
    CPHttpRequestManager * _requestManager;
    
    NSTimer              * _memoryTrackingTimer;
}

@property (nonatomic, strong, readwrite) CPInterstitialAdView * interstitialAdView;

@property (nonatomic, readonly) CPServerApi          * serverApi;
@property (nonatomic, readonly) CPPurchaseTracker    * purchaseTracker;
@property (nonatomic, readonly) CPHttpRequestManager * requestManager;

@property (nonatomic, copy, readwrite) NSString * appId;
@property (nonatomic, copy, readwrite) NSString * baseURL;

@end

@implementation CrossPromotion

@synthesize appId               = _appId;
@synthesize interstitialAdView  = _interstitialAdView;
@synthesize serverApi           = _serverApi;

+ (void)initialize
{
    if ([self class] == [CrossPromotion class])
    {
        _serverDefaultURL = kCPServerDefaultURL;
    }
}

- (id)initWithAppId:(NSString *)appId
{
    self = [super init];
    if (self)
    {
        self.appId = appId;
    }
    return self;
}

- (void)start
{
    _requestManager = [[CPHttpRequestManager alloc] init];
    
    _serverApi = [[CPServerApi alloc] initWithBaseURL:_serverDefaultURL];
    [self initSettings];
    
    [CPReachability startGeneratingNotifications];
    
    [self registerMemoryWarningObserver];
    
    _purchaseTracker = [[CPPurchaseTracker alloc] initWithSettings:_settings.iap];
    [_purchaseTracker restore];
}

- (void)dealloc
{
    [self stopRequestingInterstitials];
    [self unregisterObservers];
    
    [_purchaseTracker stop];
    
    [_requestManager cancelAll];
}

#pragma mark -
#pragma mark Settings

- (void)initSettings
{
    CPAssert(!_settings);
    CPAssert(_serverApi);
    CPAssert(_appId);
    
    _settings = [[CPSettings alloc] init];
    
    // request settings from the server async
    [self requestSettings];
}

- (void)requestSettings
{
    NSURLRequest *request = [_serverApi createPurchaseTrackerSettingsRequestWithAppId:_appId andParams:nil]; // TODO
    [_settings loadWithRequest:request completion:^(CPSettings *settings, NSError *error)
    {
        if (error != nil)
        {
            CPLogError(CPTagSettings, @"Can't load settings request: %@", error);
        }
        else
        {
            CPLogDebug(CPTagSettings, @"Settings request did finish");
            
            // installation track
            if (settings.install_tracking.enabled)
            {
                NSURL *trackingURL = settings.install_tracking.tracking_pixel_url;
                if (trackingURL)
                {
                    [self trackInstallWithURL:trackingURL];
                }
                else
                {
                    CPLogDebug(CPTagCommon, @"Can't send installation tracking request: missing tracking URL");
                }
            }
            else
            {
                CPLogDebug(CPTagCommon, @"Install tracking disabled");
            }
            
            NSDictionary *userInfo = @{
                CrossPromotionSettingsDidUpdateNotificationKeySettings : settings
            };
            [[NSNotificationCenter defaultCenter] postNotificationName:CrossPromotionSettingsDidUpdateNotification
                                                                object:nil
                                                              userInfo:userInfo];
        }
    }];
}

#pragma mark -
#pragma mark Installation tracking

- (void)trackInstallWithURL:(NSURL *)trackingURL
{
    if ([CPInstallTracking isTracked])
    {
        CPLogDebug(CPTagCommon, @"Install tracked");
    }
    else
    {
        [CPInstallTracking sendInstallTrackingRequestWithURL:trackingURL andAppId:_appId];
    }
}

#pragma mark -
#pragma mark Interstitial request

- (void)startRequestingInterstitialsWithDelegate:(id<CPInterstitialAdViewDelegate>)delegate
{
    [self stopRequestingInterstitials];
    
    self.interstitialAdView = [self createInterstitialAdView];

    CPDebugSetRequestStatus(@"Requesting interstitial ad...");
    CPLogDebug(CPTagCommon, @"Requesting interstitial ad...");
    
    NSDictionary *params = [delegate respondsToSelector:@selector(interstitialAdParams)] ? [delegate interstitialAdParams] : nil;
    
    NSURLRequest *request = [_serverApi createInitRequestWithAppId:_appId andParams:params];
    _interstitialAdView.delegate = delegate;
    [_interstitialAdView loadRequest:request];
}

- (void)stopRequestingInterstitials
{
    [self cancelMemoryTrackingTimer];
    
    _interstitialAdView.delegate = nil;
    [_interstitialAdView stop];
    
    self.interstitialAdView = nil;
}

- (CPInterstitialAdView *)createInterstitialAdView
{
    CGRect frame = CPGetApplicationFrame();
    return [[CPInterstitialAdView alloc] initWithFrame:frame];
}

#pragma mark -
#pragma mark Present/Hide

- (CPInterstitialResult)present
{
    return [self presentWithParams:nil];
}

- (CPInterstitialResult)presentWithParams:(NSDictionary *)params
{
    return _interstitialAdView != nil ? [_interstitialAdView presentWithParams:params] : CPInterstitialResultNotPresented;
}

- (BOOL)isLoaded
{
    return [_interstitialAdView isLoaded];
}

- (void)hide
{
    [_interstitialAdView hide];
}

#pragma mark -
#pragma mark Properties

- (NSString *)baseURL
{
    return [_serverApi baseURL];
}

- (void)setBaseURL:(NSString *)baseURL
{
    [_serverApi setBaseURL:baseURL];
    CPLogDebug(CPTagCommon, @"Set base URL: %@", baseURL);
}

+ (void)setWrapperName:(NSString *)wrapperName
{
    [CPServerApi setWrapperName:wrapperName];
}

+ (void)setWrapperVersion:(NSString *)wrapperVersion
{
    [CPServerApi setWrapperVersion:wrapperVersion];
}

- (CPSettings *)settings
{
    return _settings;
}

#pragma mark -
#pragma mark Observers

- (void)unregisterObservers
{
    CP_OBSERVERS_REMOVE_ALL();
}

#pragma mark -
#pragma mark Low memory handling

- (void)registerMemoryWarningObserver
{
    CP_OBSERVERS_ADD(UIApplicationDidReceiveMemoryWarningNotification, @selector(applicationDidReceiveMemoryWarningNotification:));
}

- (void)unregisterMemoryWarningObserver
{
    CP_OBSERVERS_REMOVE(UIApplicationDidReceiveMemoryWarningNotification);
}

- (void)applicationDidReceiveMemoryWarningNotification:(NSNotification *)notification
{
    [self onMemoryWarning];
}

- (void)onMemoryWarning
{
    if (_interstitialAdView != nil)
    {
        if (_settings.low_memory.enabled)
        {
            float freeMb = CP_B2MB(CPGetFreeMemory());
            if (freeMb >= _settings.low_memory.threshold)
            {
                CPLogDebug(CPTagCommon, @"Memory warning received but the free memory amount (%g) is higher than low memory threshold (%g)",
                           freeMb, _settings.low_memory.threshold);
                return;
            }
        }
        
        id<CPInterstitialAdViewDelegate> delegate = [_interstitialAdView delegate];
        
        BOOL hasDelegateMethod = [delegate respondsToSelector:@selector(interstitialAdShouldDestroyOnLowMemory)];
        BOOL delegateForbidsKill = hasDelegateMethod && ![delegate interstitialAdShouldDestroyOnLowMemory];
        
        // fill params
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        
        [params setObject:@"memory_warning" forKey:@"error[type]"];
        if (hasDelegateMethod)
        {
            CPSetBoolean(params, YES, @"error[has_delegate]");
            CPSetBoolean(params, delegateForbidsKill, @"error[no_kill]");
        };
        
        NSString *stateString = _interstitialAdView.stateName;
        if (stateString)
        {
            CPSafeSetObject(params, stateString, kCPRequestParamViewState);
        }
        
        // cleanup
        if (delegateForbidsKill)
        {
            CPLogInfo(CPTagCommon, @"Memory warning received but delegate forbids to delete ad view");
        }
        else
        {
            CPLogInfo(CPTagCommon, @"Memory warning received: deleting interstitial ad view");
            [_interstitialAdView forceClose];
            _interstitialAdView = nil;
            
            [self scheduleMemoryTrackingTimerForDelegate:delegate];
            
            if ([delegate respondsToSelector:@selector(interstitialAdLowMemoryDidDestroy)])
            {
                [delegate interstitialAdLowMemoryDidDestroy];
            }
        }
        
        [self sendMemoryWarningWithParams:params];
    }
}

- (void)sendMemoryWarningWithParams:(NSDictionary *)params
{
    CPLogDebug(CPTagNetwork, @"Send memory warning request with params: %@", params);
    
    NSURLRequest *request = [_serverApi createErrorRequestWithAppId:_appId andParams:params];
    [_requestManager queueRequest:[CPHttpRequest requestWithURLRequest:request]
                       completion:^(CPHttpRequest *request, NSError *error, BOOL cancelled) {
       if (error)
       {
           CPLogWarn(CPTagNetwork, @"Unable to send memory warning request: %@", error);
       }
       else if (cancelled)
       {
           // do nothing
       }
       else
       {
           CPLogWarn(CPTagNetwork, @"Memory warning request sent");
       }
    }];
}

#pragma mark -
#pragma mark Low memory warning timer

- (void)scheduleMemoryTrackingTimerForDelegate:(id<CPInterstitialAdViewDelegate>)delegate
{
    [self cancelMemoryTrackingTimer];
    
    if (_settings.low_memory.enabled)
    {
        NSTimeInterval timeout = _settings.low_memory.timeout_secs;
        
        CPLogDebug(CPTagCommon, @"Scheduled low memory time: %g", timeout);
        _memoryTrackingTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                                target:self
                                                              selector:@selector(onMemoryTrackingTimer:)
                                                              userInfo:delegate
                                                               repeats:YES];
    }
    else
    {
        CPLogDebug(CPTagCommon, @"Low memory time is disabled");
    }
}

- (void)cancelMemoryTrackingTimer
{
    [_memoryTrackingTimer invalidate];
    _memoryTrackingTimer = nil;
}

- (void)onMemoryTrackingTimer:(NSTimer *)timer
{
    float freeMb = CP_B2MB(CPGetFreeMemory());
    if (freeMb >= _settings.low_memory.threshold)
    {
        CPLogDebug(CPTagCommon, @"Free memory amount %g is more than the threshold %g", freeMb, _settings.low_memory.threshold);
        
        id<CPInterstitialAdViewDelegate> delegate = timer.userInfo;
        [self cancelMemoryTrackingTimer];
        if (delegate != nil)
        {
            CPLogInfo(CPTagCommon, @"Restarting ad serving (memory amount %g)...", freeMb);
            [self startRequestingInterstitialsWithDelegate:delegate];
        }
    }
}

#pragma mark -
#pragma mark Shared instance

+ (void)initializeWithAppId:(NSString *)appId
{
    if (!appId) {
        NSLog(@"CrossPromotion is not initialized. App id is nil");
        return;
    }
    
    if (!CP_SYSTEM_VERSION_AVAILABLE(CP_SYSTEM_VERSION_MIN)) {
        NSLog(@"CrossPromotion is not initialized. Minimum required OS version: %d", CP_SYSTEM_VERSION_MIN);
        return;
    }
    
    // starting ios 8 we don't need to rotate views added to a window
    CPConfigNeedsTransformForViewInWindow = !CP_SYSTEM_VERSION_AVAILABLE(__IPHONE_8_0);
    
    [self tryConnectToDebugger];
    
    CPAssert(!sharedInstance);
    sharedInstance = [[self alloc] initWithAppId:appId];
    [sharedInstance start]; // we should split initialization and startup routine since some classes may try to use
                            // a shared instance
    
    CPLogInfo(CPTagCommon, @"Initialized with app id: %@ SDK ver. %@", appId, kCPSDKVersion);
}

+ (void)destroy
{
    CPAssert(sharedInstance);
    sharedInstance = nil;
    
    [self unregisterDebugNotifications];
    
    [CPReachability stopGeneratingNotificatons];
    
    CPLogInfo(CPTagCommon, @"Destroyed");
}

+ (void)overrideDefaultServerURL:(NSString *)serverURL
{
    _serverDefaultURL = serverURL;
}

+ (void)setConfigOverrideWindowLevel:(BOOL)flag
{
    CPConfigOverrideWindowLevel = flag;
}

+ (void)setConfigNeedsTransformForViewInWindow:(BOOL)flag
{
    CPConfigNeedsTransformForViewInWindow = flag;
}

+ (CrossPromotion *)sharedInstance
{
    return sharedInstance;
}

#pragma mark -
#pragma mark Debug cheat

+ (void)tryConnectToDebugger
{
    if ([self isDebuggerInstalled])
    {
        [self tryReadDebuggerSettings];
        
        // register notification on the next run loop iteration
        dispatch_async(dispatch_get_main_queue(), ^{
            [self registerDebugNotifications];
        });
    }
}

+ (void)tryReadDebuggerSettings
{
    UIPasteboard *gpb = [UIPasteboard generalPasteboard];
    NSDictionary *settings = [self readDebugSettingsFromPasteboard:gpb];
    if (settings != nil)
    {
        [self readDebuggerSettings:settings];
    }
}

+ (void)readDebuggerSettings:(NSDictionary *)settings
{
    BOOL debuggerEnabled = [[settings objectForKey:@"debugger_enabled"] boolValue];
    if (!debuggerEnabled)
    {
        NSLog(@"Debugger disabled!");
        return;
    }
    
    BOOL catchesExceptions = [[settings objectForKey:@"exceptions_enabled"] boolValue];
    NSLog(@"Catch exceptions: %@", catchesExceptions ? @"YES" : @"NO");
    CPDebugSetCatchUnhandledExceptions(catchesExceptions);
    
    BOOL rmEnabled = [[settings objectForKey:@"rm_enabled"] boolValue];
    if (rmEnabled)
    {
        NSString *host = [settings objectForKey:@"rm_host"];
        uint16_t port = [[settings objectForKey:@"rm_port"] intValue];
        
        NSLog(@"Remote monitor enabled: %@:%d", host, port);
        CPRemoteMonitorConnect(host, port);
    }
    
    BOOL loggerEnabled = [[settings objectForKey:@"logger_enabled"] boolValue];
    CPLogLevel logLevel = CPLogLevelNone;
    if (loggerEnabled)
    {
        NSString *loggerLevelStr = [[settings objectForKey:@"logger_level"] firstObject];
        NSLog(@"Logger level: %@", loggerLevelStr);
        
        if ([loggerLevelStr isEqualToString:@"Crit"]) logLevel = CPLogLevelCrit;
        else if ([loggerLevelStr isEqualToString:@"Error"]) logLevel = CPLogLevelError;
        else if ([loggerLevelStr isEqualToString:@"Warn"]) logLevel = CPLogLevelWarn;
        else if ([loggerLevelStr isEqualToString:@"Info"]) logLevel = CPLogLevelInfo;
        else if ([loggerLevelStr isEqualToString:@"Debug"]) logLevel = CPLogLevelDebug;
        
        CPLogSetTagMask(CPTagMaskNone);
        
        NSArray *tags = [settings objectForKey:@"logger_tag"];
        NSLog(@"Logger tags: %@", tags);
        
        for (id tag in tags)
        {
            if ([tag isEqualToString:@"Common"]) CPLogSetTagEnabled(CPTagCommon, YES);
            else if ([tag isEqualToString:@"JavaScript"]) CPLogSetTagEnabled(CPTagJavaScript, YES);
            else if ([tag isEqualToString:@"Commands"]) CPLogSetTagEnabled(CPTagCommands, YES);
            else if ([tag isEqualToString:@"Network"]) CPLogSetTagEnabled(CPTagNetwork, YES);
            else if ([tag isEqualToString:@"Callbacks"]) CPLogSetTagEnabled(CPTagCallbacks, YES);
            else if ([tag isEqualToString:@"Purchase"]) CPLogSetTagEnabled(CPTagPurchase, YES);
            else if ([tag isEqualToString:@"Settings"]) CPLogSetTagEnabled(CPTagSettings, YES);
        }
    }
    
    BOOL shouldClearInstallTrack = [[settings objectForKey:@"install_track_clear"] boolValue];
    if (shouldClearInstallTrack)
    {
        NSLog(@"Clear install tracking");
        [CPInstallTracking clearTracked];
    }
    
    CPLogSetLogLevel(logLevel);
}

+ (BOOL)isDebuggerInstalled
{
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:CPDebuggerTestURL]];
}

+ (NSDictionary *)readDebugSettingsFromPasteboard:(UIPasteboard *)pasteboard
{
    NSString *string = pasteboard.string;
    if ([string rangeOfString:@"gpndebugger"].location != NSNotFound)
    {
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error = nil;
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if ([object isKindOfClass:[NSDictionary class]])
        {
            return [object objectForKey:@"gpndebugger"];
        }
    }
    
    return nil;
}

+ (void)registerDebugNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:[self class]
                                             selector:@selector(applicationDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

+ (void)unregisterDebugNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class]];
}

+ (void)applicationDidBecomeActiveNotification:(NSNotification *)notification
{
    [self tryReadDebuggerSettings];
}


///////////////////////////////////////////////////////////////

static NSUncaughtExceptionHandler * _oldUncaughtExceptionHandler;
static BOOL                         _isCatchingExceptions;

static void CPUncaughtExceptionHandler(NSException *e)
{
	NSString* trace = CP_GTMStackTraceFromException(e);
	NSString* fullMessage = [NSString stringWithFormat:@"%@: %@\r\n\r\n", [e name], [e reason]];
	fullMessage = [fullMessage stringByAppendingString:trace];
    
    NSLog(@"GPN has caught an exception:");
    NSLog(@"%@", fullMessage);
    
    UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Exception"
                                                   message:@"GPN has caught an exception!\nSee log for details!"
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
    [view show];
}

static void CPDebugSetCatchUnhandledExceptions(BOOL flag)
{
    if (flag)
    {
        if (!_isCatchingExceptions)
        {
            _oldUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
            NSSetUncaughtExceptionHandler(&CPUncaughtExceptionHandler);
        }
    }
    else
    {
        if (_isCatchingExceptions)
        {
            if (_oldUncaughtExceptionHandler)
            {
                NSSetUncaughtExceptionHandler(_oldUncaughtExceptionHandler);
                _oldUncaughtExceptionHandler = NULL;
            }
        }
    }
    
    _isCatchingExceptions = flag;
}

@end

///////////////////////////////////////////////////////////////

@implementation CrossPromotion (Reachability)

- (CPNetworkStatus)currentNetworkStatus
{
    return [CPReachability currentReachabilityStatus];
}

- (NSString *)currentNetworkStatusString
{
    return [CPReachability currentReachabilityStatusString];
}

@end

///////////////////////////////////////////////////////////////

@implementation CrossPromotion (Store)

- (void)queueTransaction:(SKPaymentTransaction *)transaction
{
    NSString *identifier        = transaction.transactionIdentifier;
    NSString *productIdentifier = transaction.payment.productIdentifier;
    NSInteger quantity          = transaction.payment.quantity;
    NSDate *date                = transaction.transactionDate;
    
    CPPayment *payment = [CPPayment paymentWithIdentifier:identifier productIdentifier:productIdentifier quantity:quantity date:date];
    [_purchaseTracker queuePayment:payment];
}

@end
