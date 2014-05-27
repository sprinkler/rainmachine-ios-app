//
//  NetworkUtilities.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/17/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "NetworkUtilities.h"
#import "NSDictionary+Keychain.h"
#import "Constants.h"

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

#pragma mark - Keychain

// Structure of our dictionary saved in keychain
// URL1
// ...
// URLn(dict) - Credentials(dict) - UserName(string)
//                                - Password(string)
//
//            - Cookies(dict) - Port 1(array of cookies)
//                            - ...
//                            - Port n(array of cookies)

+ (void)saveCookiesForBaseURL:(NSString*)baseUrl port:(NSString*)thePort username:(NSString*)username password:(NSString*)password
{
    NSString *port = thePort ? thePort : @"443";
    
    NSMutableDictionary *keychainDictionary = [[NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey] mutableCopy];
    if (!keychainDictionary) {
        keychainDictionary = [NSMutableDictionary dictionary];
    }
    
    NSMutableDictionary *urlDictionary = [[keychainDictionary objectForKey:baseUrl] mutableCopy];
    if (!urlDictionary) {
        urlDictionary = [NSMutableDictionary dictionary];
    }
    [keychainDictionary setObject:urlDictionary forKey:baseUrl];

    NSMutableDictionary *cookiesDictionary = [[urlDictionary objectForKey:kSprinklerKeychain_CookiesKey] mutableCopy];
    if (!cookiesDictionary) {
        cookiesDictionary = [NSMutableDictionary dictionary];
    }
    [urlDictionary setObject:cookiesDictionary forKey:kSprinklerKeychain_CookiesKey];
    
    NSMutableDictionary *credentialsDictionary = [[urlDictionary objectForKey:kSprinklerKeychain_CredentialsKey] mutableCopy];
    if (!credentialsDictionary) {
        credentialsDictionary = [NSMutableDictionary dictionary];
    }
    [urlDictionary setObject:credentialsDictionary forKey:kSprinklerKeychain_CredentialsKey];

    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:baseUrl]];
    
    [cookiesDictionary setObject:cookies forKey:port];
    
    [credentialsDictionary setObject:username forKey:kSprinklerKeychain_UsernameKey];
    [credentialsDictionary setObject:password forKey:kSprinklerKeychain_PasswordKey];

    [keychainDictionary storeToKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey];
}

+ (void)restoreCookieForBaseUrl:(NSString*)baseUrl port:(NSString*)thePort
{
    NSString *port = thePort ? thePort : @"443";
    NSDictionary *keychainDictionary = [NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey];
    NSArray *newCookiesForPort = [[[keychainDictionary objectForKey:baseUrl] objectForKey:kSprinklerKeychain_CookiesKey] objectForKey:port];
    
    // Delete old cookies associated with baseUrl
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:baseUrl]];
    for (NSHTTPCookie *cookie in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    
    // Set new cookies asociated with baseUrl and port
    if (newCookiesForPort) {
        for (NSHTTPCookie *cookie in newCookiesForPort) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
}

+ (NSDictionary*)keychainCredentialsForBaseUrl:(NSString*)baseUrl port:(NSString*)thePort
{
    NSString *port = thePort ? thePort : @"443";
    NSDictionary *keychainDictionary = [NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey];
    NSDictionary *credentialsDictionary = [[keychainDictionary objectForKey:baseUrl] objectForKey:kSprinklerKeychain_CredentialsKey];
    NSDictionary *cookiesDictionary = [[keychainDictionary objectForKey:baseUrl] objectForKey:kSprinklerKeychain_CookiesKey];
    
    NSMutableDictionary *rez = nil;
    if (credentialsDictionary) {
        rez = [credentialsDictionary mutableCopy];
        BOOL isSessionOnly = [NetworkUtilities containsDictionarySessionOnlyCookies:cookiesDictionary forPort:port];
        [rez setObject:[NSNumber numberWithBool:isSessionOnly] forKey:kSprinklerKeychain_isSessionOnly];
    }
    
    return rez;
}

+ (void)clearCookiesFromKeychain
{
    NSDictionary *cookiesUrlDictionary = [NSDictionary dictionary];
    [cookiesUrlDictionary storeToKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey];
}

+ (void)clearKeychainCookieForBaseUrl:(NSString*)baseUrl
{
    NSMutableDictionary *cookiesUrlDictionary = [[NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey] mutableCopy];
    [cookiesUrlDictionary removeObjectForKey:baseUrl];
    [cookiesUrlDictionary storeToKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey];
}

+ (BOOL)containsDictionarySessionOnlyCookies:(NSDictionary*)cookiesDictionary forPort:(NSString*)port
{
    BOOL isSessionOnly = NO;
    NSArray *cookies = [cookiesDictionary objectForKey:port];
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie isSessionOnly]) {
            isSessionOnly = YES;
            break;
        }
    }

    return isSessionOnly;
}

+ (void)clearSessionOnlyCookiesFromKeychain
{
    BOOL changed = NO;
    NSDictionary *keychainDictionary = [NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey];
    NSMutableDictionary *newKeychainDictionary = [keychainDictionary mutableCopy];
    
    for (NSString *urlKey in keychainDictionary) {
        NSDictionary *urlDictionary = [keychainDictionary objectForKey:urlKey];
        NSDictionary *cookiesDictionary = [urlDictionary objectForKey:kSprinklerKeychain_CookiesKey];
        for (NSString *portKey in cookiesDictionary) {
            if ([self containsDictionarySessionOnlyCookies:cookiesDictionary forPort:portKey]) {
                changed = YES;
                NSMutableDictionary *newUrlDictionary = [newKeychainDictionary[urlKey] mutableCopy];
                NSMutableDictionary *newCookiesDictionary = [[newUrlDictionary objectForKey:kSprinklerKeychain_CookiesKey] mutableCopy];
                [newCookiesDictionary removeObjectForKey:portKey];
                if ([newCookiesDictionary count] == 0) {
                    [newUrlDictionary removeObjectForKey:kSprinklerKeychain_CookiesKey];
                    [newUrlDictionary removeObjectForKey:kSprinklerKeychain_CredentialsKey];
                }
            }
        }
    }

    if (changed) {
        [newKeychainDictionary storeToKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey];
    }
}

#pragma mark - Cookies

+ (BOOL)isLoginCookieActiveForBaseUrl:(NSString*)baseUrl
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:baseUrl]];
    for (NSHTTPCookie *cookie in cookies) {
        if ([[cookie name] isEqualToString:@"login"]) {
            return YES;
        }
    }
    
    return NO;
}

+ (void)invalidateLoginForBaseUrl:(NSString*)baseUrl
{
    if (baseUrl) {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSArray *cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:baseUrl]];
        for (NSHTTPCookie *cookie in cookies) {
            [cookieStorage deleteCookie:cookie];
            DLog(@"Deleted cookie: %@", cookie);
        }
        [NetworkUtilities clearKeychainCookieForBaseUrl:baseUrl];
    }
}

@end
