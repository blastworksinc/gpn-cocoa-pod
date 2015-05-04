//
//  CPDeviceUtils.m
//  CPDeviceUtils
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

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#import <sys/utsname.h>

#import "CPDeviceUtils.h"
#import "CPCommon.h"

#if CP_IOS_SDK_AVAILABLE(__IPHONE_6_0)
#import <AdSupport/AdSupport.h>
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

static NSString* const INVALID_ADVERTISER_IDENTIFIER = @"00000000-0000-0000-0000-000000000000";

#pragma mark -
#pragma mark Unique Identifier

static NSString * CPCreateMacaddress()
{
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                           *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    return outstring;
}

NSString * CPGetMacAddressIdentifier()
{
    NSString *macaddress = CPCreateMacaddress();
    NSString *uniqueIdentifier = CPCalculateMD5(macaddress);
    
    return uniqueIdentifier;
}

NSString * CPCreateUniqueAdvertisingIdentifier()
{
#if CP_IOS_SDK_AVAILABLE(__IPHONE_6_0)
    if (CP_CLASS_AVAILABLE(ASIdentifierManager))
    {
        NSString *advertisingIdentifier = [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
        if ([advertisingIdentifier isEqualToString:INVALID_ADVERTISER_IDENTIFIER])
        {
            return nil;
        }
        
        return advertisingIdentifier;
    }
#endif
    
    return nil;
}

CPAdvertisingTrackingState CPGetUniqueAdvertisingIdentifierTrackerState()
{
#if CP_IOS_SDK_AVAILABLE(__IPHONE_6_0)
    
    if (CP_CLASS_AVAILABLE(ASIdentifierManager))
    {
        BOOL enabled = [ASIdentifierManager sharedManager].advertisingTrackingEnabled;
        return enabled ? CPAdvertisingTrackingStateEnabled : CPAdvertisingTrackingStateDisabled;
    }
    
#endif
    return CPAdvertisingTrackingStateUnknown;
}

#pragma mark -
#pragma mark Locale

NSString * CPGetLocaleCountry()
{
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

CTCarrier * CPGetCarrierInfo()
{
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    return [netinfo subscriberCellularProvider];
}

#pragma mark -
#pragma mark Memory usage

natural_t CPGetUsedMemory()
{
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    if (task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size) != KERN_SUCCESS)
    {
        return 0;
    }
        
    return info.resident_size;
}

natural_t CPGetFreeMemory(void)
{
    CPMemoryUsageInfo info;
    if (CPGetMemoryUsageInfo(&info))
    {
        return info.free;
    }
    
    return 0;
}

BOOL CPGetMemoryUsageInfo(CPMemoryUsageInfo* info)
{
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
    {
        return false;
    }
    
    /* Stats in bytes */
    natural_t mem_used = (vm_stat.active_count +
                          vm_stat.inactive_count +
                          vm_stat.wire_count) * pagesize;
    natural_t mem_free = vm_stat.free_count * pagesize;
    natural_t mem_total = mem_used + mem_free;
    
    info->free  = mem_free;
    info->used  = mem_used;
    info->total = mem_total;
    
    return true;
}

NSString *CPGetDeviceMachine(void)
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

#pragma clang diagnostic pop
