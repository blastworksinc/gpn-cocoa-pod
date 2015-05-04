//
//  CPGpnView.m
//  CPGpnView
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

#import "CPGpnView_Controllers.h"

#import "CPCommon.h"
#import "CPWebView.h"

static const int kCPWebKitErrorFrameLoadInterruptedByPolicyChange = 102;

static const float kCPMemorySamplingInterval    = 5.0f; // sample free memory every 5 sec
static const float kCPMemorySamplingThreshold   = 5.0f; // notify about every 5 Mb diff

static NSString * const kCPWebKitErrorDomain = @"WebKitErrorDomain";
static NSString * const kGpnURLScheme        = @"gpn";
static NSString * const kGpnCommandId        = @"id";

static NSDictionary *MPDictionaryFromQueryString(NSString *query);

@interface CPGpnView () <UIWebViewDelegate>
{
    UIWebView               * _webView;
    CPGpnDisplayController  * _displayController;
    CPGpnCommandManager     * _commandManager;
    CPFreeMemorySampler     * _memorySampler;

    BOOL _isLoading;
    BOOL _isModalShowing;
    
    NSArray * _specialURLs;
}

@property (nonatomic, retain) UIWebView * webView;

@end

@interface CPGpnCommand (Internal)

+ (NSMutableDictionary *)sharedCommandClassMap;
+ (void)registerCommand:(Class)commandClass;
+ (NSString *)commandType;
+ (id)commandForString:(NSString *)string;

- (void)execute;
- (void)cancel;

- (CGFloat)floatFromParametersForKey:(NSString *)key;
- (CGFloat)floatFromParametersForKey:(NSString *)key withDefault:(CGFloat)defaultValue;
- (BOOL)boolFromParametersForKey:(NSString *)key;
- (int)intFromParametersForKey:(NSString *)key;
- (NSString *)stringFromParametersForKey:(NSString *)key;

@end

@implementation CPGpnView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;

        [self addWebViewWithFrame:frame];
        
        _displayController = [[CPGpnDisplayController alloc] initWithAdView:self];
        
        _commandManager = [[CPGpnCommandManager alloc] init];
        [self registerReachabilityObserver];
        [self registerFreeMemorySamplerNotification];
        
        _specialURLs = [[NSArray alloc] initWithObjects:@"itunes.apple.com", @"phobos.apple.com", @"maps.google.com", @"maps.apple.com", nil];
        _memorySampler = [[CPFreeMemorySampler alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self stopSamplingMemory];
    [self cancelAllCommands];
    
    self.webView = nil;
    self.displayController.adView = nil;
}

#pragma mark -
#pragma mark Loading

- (void)loadCreativeWithHTMLString:(NSString *)html baseURL:(NSURL *)url
{
    _isLoading = YES;
    [self loadHTMLString:html baseURL:url];
}

- (void)loadCreativeWithURLRequest:(NSURLRequest *)request
{
    _isLoading = YES;
    [self loadURLRequest:request];
}

- (void)stopLoading
{
    [_webView stopLoading];
    _isLoading = NO;
}

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
    [_webView loadHTMLString:string baseURL:baseURL];
}

- (void)loadURLRequest:(NSURLRequest *)request
{
    [_webView loadRequest:request];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];
    NSMutableString *urlString = [NSMutableString stringWithString:[url absoluteString]];
    NSString *scheme = url.scheme;
    
    if ([scheme isEqualToString:kGpnURLScheme])
    {
        [self tryProcessingURLStringAsCommand:urlString];
        return NO;
    }
    
    if ([scheme isEqualToString:@"ios-log"])
    {
        NSString *logString = CPUnescapeString(urlString);
        CPLogDebug(CPTagJavaScript, @"%@", logString);
        return NO;
    }
    
    if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"])
    {
        if ([[UIApplication sharedApplication] canOpenURL:url])
        {
            [self openSpecialUrl:url];
            return NO;
        }
    }
    
    NSString *host = url.host;
    for (NSString *specialURL in _specialURLs)
    {
        if ([host hasPrefix:specialURL])
        {
            [self openSpecialUrl:url];
            return NO;
        }
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (_isLoading)
    {
        _isLoading = NO;
        [self initializeJavascriptState];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) return;
    if ([error.domain isEqualToString:kCPWebKitErrorDomain] && error.code == kCPWebKitErrorFrameLoadInterruptedByPolicyChange) return; // seen after itunes links
    
    _isLoading = NO;
    [self adDidFailToLoadError:error];
}

#pragma mark -
#pragma mark Application handled URLs

- (void)openSpecialUrl:(NSURL *)url
{
    [self registerResumeObserver];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark -
#pragma mark Presentation

- (void)presentWithParams:(NSDictionary *)params
{
    if (params != nil)
    {
        [self fireChangeEventForProperty:[CPGpnParamsProperty propertyWithParams:params]];
    }
    
    [self adWillPresentModalView];
    [_displayController present];
}

#pragma mark -
#pragma mark JavaScript

- (NSString *)executeJavascript:(NSString *)javascript, ...
{
    va_list args;
    va_start(args, javascript);
    NSString *result = [self executeJavascript:javascript withVarArgs:args];
    va_end(args);
    return result;
}

- (NSString *)executeJavascript:(NSString *)javascript withVarArgs:(va_list)args
{
    NSString *js = [[NSString alloc] initWithFormat:javascript arguments:args];
    CPLogDebug(CPTagJavaScript, @"Javascript call: '%@'", js);
    NSString *result = [_webView stringByEvaluatingJavaScriptFromString:js];
    if (result.length > 0) {
        CPLogDebug(CPTagJavaScript, @"Javascript result: '%@'", result);
    }
    return result;
}

- (void)initializeJavascriptState
{
    [_displayController initializeJavascriptState];
    [self fireReadyEvent];
}

#pragma mark -
#pragma mark JavaScript Communication API

- (void)fireChangeEventForProperty:(CPGpnProperty *)property
{
    NSString *JSON = [NSString stringWithFormat:@"{%@}", property];
    [self executeJavascript:@"window.gpnbridge.fireChangeEvent(%@);", JSON];
}

- (void)fireChangeEventsForProperties:(NSArray *)properties
{
    NSString *JSON = [NSString stringWithFormat:@"{%@}",
                      [properties componentsJoinedByString:@", "]];
    [self executeJavascript:@"window.gpnbridge.fireChangeEvent(%@);", JSON];
}

- (void)fireErrorEventForAction:(NSString *)action withMessage:(NSString *)message
{
    [self executeJavascript:@"window.gpnbridge.fireErrorEvent('%@', '%@');", message, action];
}

- (void)fireReadyEvent
{
    [self executeJavascript:@"window.gpnbridge.fireReadyEvent();"];
}

- (void)firePresentingState
{
    [self fireChangeEventForProperty:[CPGpnStateProperty propertyWithState:CPGpnViewStatePresenting]];
}

- (void)fireDidCompleteCommandId:(NSString *)commandId
{
    [self executeJavascript:@"window.gpnbridge.nativeCallComplete('%@');", commandId];
}

- (void)fireDidFailCommandId:(NSString *)commandId
{
    [self executeJavascript:@"window.gpnbridge.nativeCallFailed('%@');", commandId]; // TODO: add command's parameters
}

- (void)fireDidCancelCommandId:(NSString *)commandId
{
    [self executeJavascript:@"window.gpnbridge.nativeCallCancelled('%@');", commandId];
}

#pragma mark -
#pragma mark Commands

- (BOOL)tryProcessingURLStringAsCommand:(NSString *)urlString
{
    NSString *scheme = [NSString stringWithFormat:@"%@://", kGpnURLScheme];
    NSString *schemelessUrlString = [urlString substringFromIndex:scheme.length];
    
    NSRange r = [schemelessUrlString rangeOfString:@"?"];
    
    if (r.location == NSNotFound)
    {
        CPLogError(CPTagCommands, @"Command is supposed to have params");
        [self fireDidFailCommandId:nil];
        return NO;
    }
    
    NSString *commandType = [[schemelessUrlString substringToIndex:r.location] lowercaseString];
    NSString *parameterString = [schemelessUrlString substringFromIndex:(r.location + 1)];
    NSDictionary *parameters = MPDictionaryFromQueryString(parameterString);
    
    return [self tryProcessingCommand:commandType parameters:parameters];
}

- (BOOL)tryProcessingCommand:(NSString *)commandName parameters:(NSDictionary *)parameters
{
    NSString *commandId = [parameters objectForKey:kGpnCommandId];
    if (commandId == nil) {
        CPLogError(CPTagCommands, @"Missing command id:'%@' params:%@", commandName, parameters);
        [self fireDidFailCommandId:nil];
        return NO;
    }
    
    CPGpnCommand *cmd = [CPGpnCommand commandForString:commandName];
    if (cmd == nil) {
        CPLogDebug(CPTagCommands, @"Unknown command:'%@' params:%@", commandName, parameters);
        [self fireDidFailCommandId:commandId];
        return NO;
    }
    
    cmd.commandId  = commandId;
    cmd.parameters = parameters;
    cmd.view = self;
    
    __CP_BLOCKSAFE CPGpnView *blockSafeSelf = self;
    [_commandManager executeCommand:cmd callback:^(CPGpnCommand *command, NSError *error) {
        if (error != nil) {
            [blockSafeSelf fireDidFailCommandId:commandId];
        } else if (command.cancelled) {
            [blockSafeSelf fireDidCancelCommandId:commandId];
        } else {
            [blockSafeSelf fireDidCompleteCommandId:commandId];
        }
    }];
    
    return YES;
}

- (BOOL)tryCancelCommandWithId:(NSString *)commandId
{
    return [_commandManager cancelCommandWithId:commandId];
}

- (void)cancelAllCommands
{
    [_commandManager cancelAllCommands];
}

#pragma mark -
#pragma mark Suspend/Resume

- (void)registerResumeObserver
{
    [self registerObserver:UIApplicationWillEnterForegroundNotification selector:@selector(onBackToApplication)];
}

- (void)unregisterResumeObserver
{
    [self unregisterObserver:UIApplicationWillEnterForegroundNotification];
}

- (void)onBackToApplication
{
    [self unregisterResumeObserver];
}

#pragma mark -
#pragma mark Reachability notification

- (void)registerReachabilityObserver
{
    CP_OBSERVERS_ADD(CPReachabilityDidChangeNotification, @selector(reachabilityDidChangeNotification:));
}

- (void)unregisterReachabilityObserver
{
    CP_OBSERVERS_REMOVE(CPReachabilityDidChangeNotification);
}

- (void)reachabilityDidChangeNotification:(NSNotification *)notification
{
    NSString *status = [CPReachability currentReachabilityStatusString];
    [self fireChangeEventForProperty:[CPGpnNetworkReachabilityProperty propertyWithState:status]];
}

#pragma mark -
#pragma mark Free memory sampler notifications

- (void)registerFreeMemorySamplerNotification
{
    CP_OBSERVERS_ADD(CPFreeMemoryDidChangedNotification, @selector(freeMemoryDidChangedNotification:));
}

- (void)unregisterFreeMemorySamplerNotification
{
    CP_OBSERVERS_REMOVE(CPFreeMemoryDidChangedNotification);
}

- (void)freeMemoryDidChangedNotification:(NSNotification *)notification
{
    NSNumber *freeAmountNumber = (NSNumber *)notification.object;
    [self fireChangeEventForProperty:[CPGpnFreeMemoryProperty propertyWithFreeMegabytes:[freeAmountNumber floatValue]]];
}

#pragma mark -
#pragma mark Delegate notifications

- (void)adDidLoad
{
    [self startSamplingMemory];
    
    if ([self.delegate respondsToSelector:@selector(adDidLoad:)])
    {
        [self.delegate adDidLoad:self];
    }
}

- (void)adDidFailToLoadError:(NSError *)error
{
    [self stopSamplingMemory];
    
    if ([self.delegate respondsToSelector:@selector(adDidFailToLoad:withError:)])
    {
        [self.delegate adDidFailToLoad:self withError:error];
    }
}

- (void)adPageDidLoad
{
    if ([self.delegate respondsToSelector:@selector(adPageDidLoad:)])
    {
        [self.delegate adPageDidLoad:self];
    }
}

- (void)adPageDidFailToLoadWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(adPageDidFailToLoad:withError:)])
    {
        [self.delegate adPageDidFailToLoad:self withError:error];
    }
}

#pragma mark -
#pragma mark Controllers

- (void)adWillPresentModalView
{
    CPAssert(!_isModalShowing);
    
    _isModalShowing = YES;
    [self notifyWillPresentModalView];
}

- (void)adDidPresentModalView
{
    CPAssert(_isModalShowing);
    [self notifyDidPresentModalView];
}

- (void)adWillDismissModalView
{
    CPAssert(_isModalShowing);
    [self notifyWillDismissModalView];
}

- (void)adDidDismissModalView
{
    CPAssert(_isModalShowing);
    
    _isModalShowing = NO;
    [self notifyDidDismissModalView];
}

- (void)hide
{
    [self fireChangeEventForProperty:[CPGpnStateProperty propertyWithState:CPGpnViewStateHidden]];
    [self cancelAllCommands];
}

#pragma mark -
#pragma mark Delegate notifications

- (void)notifyWillPresentModalView
{
    if ([self.delegate respondsToSelector:@selector(adWillPresentModalView:)])
    {
        [self.delegate adWillPresentModalView:self];
    }
}

- (void)notifyDidPresentModalView
{
    if ([self.delegate respondsToSelector:@selector(adDidPresentModalView:)])
    {
        [self.delegate adDidPresentModalView:self];
    }
}

- (void)notifyWillDismissModalView
{
    if ([self.delegate respondsToSelector:@selector(adWillDismissModalView:)])
    {
        [self.delegate adWillDismissModalView:self];
    }
}

- (void)notifyDidDismissModalView
{
    if ([self.delegate respondsToSelector:@selector(adDidDismissModalView:)])
    {
        [self.delegate adDidDismissModalView:self];
    }
}

#pragma mark -
#pragma mark UIWebView

- (void)addWebViewWithFrame:(CGRect)frame
{
    _webView = [[CPWebView alloc] initWithFrame:frame];
    _webView.mediaPlaybackRequiresUserAction = NO;
    _webView.allowsInlineMediaPlayback = YES;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.clipsToBounds = YES;
    _webView.delegate = self;
    _webView.opaque = NO;
    
    [self disableScrollForWebView:_webView];
    
    if ([_webView respondsToSelector:@selector(setAllowsInlineMediaPlayback:)])
    {
        [_webView setAllowsInlineMediaPlayback:YES];
    }
    
    if ([_webView respondsToSelector:@selector(setMediaPlaybackRequiresUserAction:)])
    {
        [_webView setMediaPlaybackRequiresUserAction:NO];
    }
    
    [self addSubview:_webView];
}

- (void)disableScrollForWebView:(UIWebView *)webView
{
    UIScrollView *scrollView = nil;
    if ([webView respondsToSelector:@selector(scrollView)])
    {
        scrollView = [webView scrollView];
    }
    else // pre iOS 5.0
    {
        for (id v in self.subviews)
        {
            if ([v isKindOfClass:[UIScrollView class]])
            {
                scrollView = v;
                break;
            }
        }
    }
    
    scrollView.scrollEnabled = NO;
    scrollView.bounces = NO;
}

- (void)setWebView:(UIWebView *)webView
{
    if (_webView != webView)
    {
        [_webView setDelegate:nil];
        [_webView removeFromSuperview];
        
        _webView = webView;
    }
}

#pragma mark -
#pragma mark Memory sampler

- (void)startSamplingMemory
{
    [_memorySampler startSamplingWithInterval:kCPMemorySamplingInterval andThreshold:kCPMemorySamplingThreshold];
}

- (void)stopSamplingMemory
{
    [_memorySampler stopSampling];
}

#pragma mark -
#pragma mark Helpers

NSDictionary *MPDictionaryFromQueryString(NSString *query)
{
    NSMutableDictionary *queryDict = [NSMutableDictionary dictionary];
	NSArray *queryElements = [query componentsSeparatedByString:@"&"];
	for (NSString *element in queryElements) {
		NSArray *keyVal = [element componentsSeparatedByString:@"="];
		NSString *key = [keyVal objectAtIndex:0];
		NSString *value = [keyVal lastObject];
		CPSafeSetObject(queryDict, [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], key);
	}
	return queryDict;
}

@end
