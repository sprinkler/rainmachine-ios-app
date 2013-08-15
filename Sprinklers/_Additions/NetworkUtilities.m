//
//  NetworkUtilities.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/17/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "NetworkUtilities.h"

#include <arpa/inet.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <errno.h>
#include <ifaddrs.h>
#include <stdio.h>

static NSString *kWifiInterface = @"en0";

@implementation NetworkUtilities

+ (NSString *)broadcastAddressForAddress:(NSString *)ipAddress withMask:(NSString *)netmask {
    NSAssert(nil != ipAddress, @"IP address cannot be nil");
    NSAssert(nil != netmask, @"Netmask cannot be nil");
    NSArray *ipChunks = [ipAddress componentsSeparatedByString:@"."];
    NSAssert([ipChunks count] == 4, @"IP does not have 4 octets!");
    NSArray *nmChunks = [netmask componentsSeparatedByString:@"."];
    NSAssert([nmChunks count] == 4, @"Netmask does not have 4 octets!");
    
    NSUInteger ipRaw = 0;
    NSUInteger nmRaw = 0;
    NSUInteger shift = 24;
    for (NSUInteger i = 0; i < 4; ++i, shift -= 8) {
        ipRaw |= [[ipChunks objectAtIndex:i] intValue] << shift;
        nmRaw |= [[nmChunks objectAtIndex:i] intValue] << shift;
    }
    
    NSUInteger bcRaw = ~nmRaw | ipRaw;
    return [NSString stringWithFormat:@"%d.%d.%d.%d", (bcRaw & 0xFF000000) >> 24,
            (bcRaw & 0x00FF0000) >> 16, (bcRaw & 0x0000FF00) >> 8, bcRaw & 0x000000FF];
}

+ (NSString *)ipAddressForInterface:(NSString *)ifName {
    NSAssert(nil != ifName, @"Interface name cannot be nil");
    
    struct ifaddrs *addrs = NULL;
    if (getifaddrs(&addrs)) {
        NSLog(@"Failed to enumerate interfaces: %@", [NSString stringWithCString:strerror(errno) encoding:NSASCIIStringEncoding]);
        return nil;
    }
    
    /* walk the linked-list of interfaces until we find the desired one */
    NSString *addr = nil;
    struct ifaddrs *curAddr = addrs;
    while (curAddr != NULL) {
        if (AF_INET == curAddr->ifa_addr->sa_family) {
            NSString *curName = [NSString stringWithCString:curAddr->ifa_name encoding:NSASCIIStringEncoding];
            if ([ifName isEqualToString:curName]) {
                char* cstring = inet_ntoa(((struct sockaddr_in *)curAddr->ifa_addr)->sin_addr);
                addr = [NSString stringWithCString:cstring encoding:NSASCIIStringEncoding];
                break;
            }
        }
        curAddr = curAddr->ifa_next;
    }
    
    /* clean up, return what we found */
    freeifaddrs(addrs);
    return addr;
}

+ (NSString *)ipAddressForWifi {
    return [NetworkUtilities ipAddressForInterface:kWifiInterface];
}

+ (NSString *)netmaskForInterface:(NSString *)ifName {
    NSAssert(nil != ifName, @"Interface name cannot be nil");
    
    struct ifreq ifr;
    strncpy(ifr.ifr_name, [ifName UTF8String], IFNAMSIZ-1);
    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (-1 == fd) {
        NSLog(@"Failed to open socket to get netmask");
        return nil;
    }
    
    if (-1 == ioctl(fd, SIOCGIFNETMASK, &ifr)) {
        NSLog(@"Failed to read netmask: %@", [NSString stringWithCString:strerror(errno) encoding:NSASCIIStringEncoding]);
        close(fd);
        return nil;
    }
    
    close(fd);
    char *cstring = inet_ntoa(((struct sockaddr_in *)&ifr.ifr_addr)->sin_addr);
    return [NSString stringWithCString:cstring encoding:NSASCIIStringEncoding];
}

+ (NSString *)netmaskForWifi {
    return [NetworkUtilities netmaskForInterface:kWifiInterface];
}

@end
