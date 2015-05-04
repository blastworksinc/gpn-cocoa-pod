//
//  CPServerApi.m
//  CPServerApi
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

#import "CPServerApi.h"
#import "CPCommon.h"

static NSString * const kCPServerPathInit     = @"api/init";
static NSString * const kCPServerPathError    = @"api/error";
static NSString * const kCPServerPathSettings = @"api/sdks/init";

static NSString * _wrapperVersion;
static NSString * _wrapperName;

// TODO: refactor this class

@implementation CPServerApi

- (id)initWithBaseURL:(NSString *)baseURL
{
    self = [super init];
    if (self)
    {
        if (baseURL == nil)
        {
            [NSException raise:NSInvalidArgumentException
                        format:@"'baseURL' should not be nil"];
        }
        _baseURL = baseURL;
    }
    return self;
}


#pragma mark -
#pragma mark Requests

- (NSURLRequest *)createInitRequestWithAppId:(NSString *)appId andParams:(NSDictionary *)optionalParams
{
    NSURLRequest *request = [self createURLRequestWithPath:kCPServerPathInit appId:appId andParams:optionalParams];
    CPLogDebug(CPTagNetwork, @"Init request with URL: %@", [[request URL] absoluteString]);
    
    return request;
}

- (NSURLRequest *)createErrorRequestWithAppId:(NSString *)appId andParams:(NSDictionary *)optionalParams
{
    NSURLRequest *request = [self createURLRequestWithPath:kCPServerPathError appId:appId andParams:optionalParams];
    CPLogDebug(CPTagNetwork, @"Error request with URL: %@", [[request URL] absoluteString]);
    
    return request;
}

- (NSURLRequest *)createPurchaseTrackerSettingsRequestWithAppId:(NSString *)appId andParams:(NSDictionary *)optionalParams
{
    NSURLRequest *request = [self createURLRequestWithPath:kCPServerPathSettings appId:appId andParams:optionalParams];
    CPLogDebug(CPTagNetwork, @"Purchase settings request with URL: %@", [[request URL] absoluteString]);
    
    return request;
}

- (NSURLRequest *)createPurchaseTrackingRequestWithAppId:(NSString *)appId
                                             trackingURL:(NSURL *)trackingURL
                                               andParams:(NSDictionary *)optionalParams
{
    NSURLRequest *request = [self createURLRequestWithString:trackingURL.absoluteString appId:appId andParams:optionalParams];
    CPLogDebug(CPTagNetwork, @"Purchase tracking request with URL: %@", [[request URL] absoluteString]);
    
    return request;
}

- (NSURLRequest *)createInstallTrackingRequestWithAppId:(NSString *)appId
                                            trackingURL:(NSURL *)trackingURL
                                              andParams:(NSDictionary *)params
{
    NSURLRequest *request = [self createURLRequestWithString:trackingURL.absoluteString appId:appId andParams:params];
    CPLogDebug(CPTagNetwork, @"Install tracking request with URL: %@", [[request URL] absoluteString]);
    
    return request;
}

- (NSURLRequest *)createURLRequestWithPath:(NSString *)path appId:(NSString *)appId andParams:(NSDictionary *)optionalParams
{
    NSDictionary *params = [self appParamsWithAppId:appId andOptionalParams:optionalParams];
    NSURL *url = [self createURLWithPath:path andParams:params];
    
    return [NSURLRequest requestWithURL:url];
}

- (NSURLRequest *)createURLRequestWithString:(NSString *)URLString appId:(NSString *)appId andParams:(NSDictionary *)optionalParams
{
    NSDictionary *params = [self appParamsWithAppId:appId andOptionalParams:optionalParams];
    NSURL *url = [self createURLWithString:URLString andParams:params];
    
    return [NSURLRequest requestWithURL:url];
}

- (NSDictionary *)appParamsWithAppId:(NSString *)appId andOptionalParams:(NSDictionary *)optionalParams
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    // app id
    CPSafeSetObject(params, appId, kCPRequestParamAppId);
    
    // bundle id
    CPSafeSetObject(params, [NSBundle mainBundle].bundleIdentifier, kCPRequestBundleId);
    
    // bundle version
    NSString *bundleVersion = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleVersion"];
    if (bundleVersion != nil)
    {
        CPSafeSetObject(params, bundleVersion, kCPRequestAppVersionCode);
    }
    
    // bundle version short string
    NSString *bundleVersionStr = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleShortVersionString"];
    if (bundleVersionStr != nil)
    {
        CPSafeSetObject(params, bundleVersionStr, kCPRequestAppVersionName);
    }
    
    // sdk version
    CPSafeSetObject(params, kCPSDKVersion, kCPRequestParamSDKVersion);
    
    // connection type
    NSString *connectionType = [[CrossPromotion sharedInstance] currentNetworkStatusString];
    CPTrySetObject(params, connectionType, kCPRequestParamConnectionType);
    
    // advertising identfiner for iOS6+
    NSString *advertisingIdentifier = CPCreateUniqueAdvertisingIdentifier();
    if (advertisingIdentifier != nil)
    {
        CPSafeSetObject(params, advertisingIdentifier, kCPRequestParamAdvertisingIdentifier);
        CPAdvertisingTrackingState trackingState = CPGetUniqueAdvertisingIdentifierTrackerState();
        if (trackingState != CPAdvertisingTrackingStateUnknown)
        {
            CPSetInteger(params, trackingState, kCPRequestParamAdvertisingTracker);
        }
    }
    
    // mac id
    NSString* macid = CPGetMacAddressIdentifier();
    CPTrySetObject(params, macid, kCPRequestParamMacId);
    
    // country
    NSString *country = CPGetLocaleCountry();
    CPTrySetObject(params, country, kCPRequestParamCountry);
    
    // carrier
    CTCarrier * carrier = CPGetCarrierInfo();
    if (carrier != nil)
    {
        CPTrySetObject(params, carrier.carrierName, kCPRequestParamCarrier);
    }
    
    // display size
    CGSize screenSize = CPGetScreenBounds().size;
    int screenWidth = (int)screenSize.width;
    int screenHeight = (int)screenSize.height;
    CPSetInteger(params, screenWidth, kCPRequestParamScreenWidth);
    CPSetInteger(params, screenHeight, kCPRequestParamScreenHeight);
    
    // free memory
    float freeMb = CP_B2MB(CPGetFreeMemory());
    CPSetFloat(params, freeMb, kCPRequestParamFreeMemory);
    
    // device info
    CPSafeSetObject(params, @"iOS", kCPRequestParamSystemPlatform);
    CPSafeSetObject(params, CPGetDeviceMachine(), kCPRequestParamSystemDevice);
    CPSafeSetObject(params, [UIDevice currentDevice].systemVersion, kCPRequestParamSystemVersion);
    
    // wrapper name
    if (_wrapperName && _wrapperVersion)
    {
        CPSafeSetObject(params, _wrapperName, kCPRequestParamWrapperName);
        CPSafeSetObject(params, _wrapperVersion, kCPRequestParamWrapperVersion);
    }
    
    // debug mode
    if (CPIsDebugEnabled())
    {
        [params setObject:@"true" forKey:kCPRequestParamDebug];
    }
    
    if (optionalParams.count > 0)
    {
        [params addEntriesFromDictionary:optionalParams];
    }
    
    return params;
}

#pragma mark -
#pragma mark Helpers

- (NSURL *)createURLWithPath:(NSString *)path andParams:(NSDictionary *)params
{
    NSString *URLString = [NSString stringWithFormat:@"%@/%@", _baseURL, path];
    return [self createURLWithString:URLString andParams:params];
}

- (NSURL *)createURLWithString:(NSString *)URLString andParams:(NSDictionary *)params
{
    NSMutableString *absoluteString = [NSMutableString stringWithString:URLString];
    if (params.count > 0)
    {
        [absoluteString appendFormat:@"?%@", CPCreateQueryString(params, NSUTF8StringEncoding)];
    }
    
    return [NSURL URLWithString:absoluteString];
}

#pragma mark -
#pragma mark Wrappers

+ (void)setWrapperName:(NSString *)name
{
    _wrapperName = name;
}

+ (void)setWrapperVersion:(NSString *)version
{
    _wrapperVersion = version;
}

@end
