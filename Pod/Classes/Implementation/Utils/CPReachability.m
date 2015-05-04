//
//  CPReachability.m
//  CPReachability
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

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "CPReachability.h"
#import "CPUtils.h"

static CPReachability * _sharedInstance = nil;

@interface CPReachability ()
{
    SCNetworkReachabilityRef _reachabilityRef;
}
@end

@implementation CPReachability

- (void)dealloc
{
    [self unscheduleNotificatons];
    if(_reachabilityRef != NULL)
    {
        CFRelease(_reachabilityRef);
        _reachabilityRef = NULL;
    }
}

+ (CPReachability *)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress;
{
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault,
                                                                                   (const struct sockaddr*)hostAddress);
    CPReachability* retVal = NULL;
    if(reachability != NULL)
    {
        retVal = [[self alloc] init];
        if(retVal != NULL)
        {
            retVal->_reachabilityRef = reachability;
        }
    }
    return retVal;
}

+ (CPReachability *)reachabilityForInternetConnection;
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    return [self reachabilityWithAddress: &zeroAddress];
}

#pragma mark -
#pragma mark Notifier

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CPReachabilityDidChangeNotification object:nil];
}

+ (BOOL)startGeneratingNotifications
{
    return [[self sharedInstance] scheduleNotifications];
}

+ (void)stopGeneratingNotificatons
{
    [[self sharedInstance] unscheduleNotificatons];
}

- (BOOL)scheduleNotifications
{
    BOOL retVal = NO;
    SCNetworkReachabilityContext context = {0, NULL, NULL, NULL, NULL};
    if(SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityCallback, &context))
    {
        if(SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode))
        {
            retVal = YES;
            CPLogDebug(CPTagCommon, @"Reachability started generating notifications");
        }
    }
    return retVal;
}

- (void)unscheduleNotificatons
{
    if(_reachabilityRef != NULL)
    {
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CPLogDebug(CPTagCommon, @"Reachability stopped generating notifications");
    }
}

#pragma mark -
#pragma mark Network Flag Handling

- (CPNetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags
{
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
    {
        // if target host is not reachable
        return CPNetworkStatusUnreachable;
    }
    
    CPNetworkStatus retVal = CPNetworkStatusUnreachable;
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
    {
        // if target host is reachable and no connection is required
        //  then we'll assume (for now) that your on Wi-Fi
        retVal = CPNetworkStatusReachableWiFi;
    }
    
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
    {
        // ... and the connection is on-demand (or on-traffic) if the
        //     calling application is using the CFSocketStream or higher APIs
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            // ... and no [user] intervention is needed
            retVal = CPNetworkStatusReachableWiFi;
        }
    }
    
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
    {
        // ... but WWAN connections are OK if the calling application
        //     is using the CFNetwork (CFSocketStream?) APIs.
        retVal = CPNetworkStatusReachableCarrier;
    }
    return retVal;
}

- (CPNetworkStatus)resolveReachabilityStatus
{
    CPAssert(_reachabilityRef != NULL);
    
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags))
    {
        return [self networkStatusForFlags:flags];
    }
    return CPNetworkStatusReachableUnknown;
}

+ (CPNetworkStatus)currentReachabilityStatus
{
    return [[self sharedInstance] resolveReachabilityStatus];
}
              
+ (NSString *)currentReachabilityStatusString
{
    CPNetworkStatus status = [self currentReachabilityStatus];
    switch (status) {
        case CPNetworkStatusReachableWiFi:
            return CPNetworkReachableWiFi;
        case CPNetworkStatusReachableCarrier:
            return CPNetworkReachableCarrier;
        case CPNetworkStatusUnreachable:
            return CPNetworkUnreachable;
        case CPNetworkStatusReachableUnknown:
            return CPNetworkReachableUnknown;
    }
    
    return CPNetworkReachableUnknown;
}

+ (CPReachability *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [CPReachability reachabilityForInternetConnection];
    });
    
    return _sharedInstance;
}

@end
