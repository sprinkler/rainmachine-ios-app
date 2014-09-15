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
#import "StorageManager.h"
#import "ServerProxy.h"
#import "Login4Response.h"

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

+ (NSArray*)cookiesForURL:(NSURL*)url
{
    NSMutableArray *results = [NSMutableArray array];
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    NSString *address = [url absoluteString];
    
    for (NSHTTPCookie *cookie in cookies) {
        if ([address rangeOfString:cookie.domain].location != NSNotFound) {
            [results addObject:cookie];
        }
    }
    
    return results;
}
// Structure of our dictionary saved in keychain
// URL1
// ...
// URLn(dict) - Credentials(dict) - UserName(string)
//                                - Password(string)
//
//            - Cookies(dict) - Port 1(array of cookies)
//                            - ...
//                            - Port n(array of cookies)

+ (void)saveCookiesForBaseURL:(NSString*)baseUrl port:(NSString*)thePort
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
    
    NSArray *cookies = [NetworkUtilities cookiesForURL:[NSURL URLWithString:baseUrl]];
    [cookiesDictionary setObject:cookies forKey:port];
    
    [keychainDictionary storeToKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey];
}

+ (void)restoreCookieForBaseUrl:(NSString*)baseUrl port:(NSString*)thePort
{
    NSString *port = thePort ? thePort : @"443";
    NSDictionary *keychainDictionary = [NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey];
    NSArray *newCookiesForPort = [[[keychainDictionary objectForKey:baseUrl] objectForKey:kSprinklerKeychain_CookiesKey] objectForKey:port];
    
    // Delete old cookies associated with baseUrl
    NSArray *cookies = [NetworkUtilities cookiesForURL:[NSURL URLWithString:baseUrl]];
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

+ (void)clearCookiesFromKeychain
{
    NSDictionary *keychainDictionary = [NSDictionary dictionary];
    [keychainDictionary storeToKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey];
}

+ (void)clearKeychainCookieForBaseUrl:(NSString*)baseUrl port:(NSString*)port
{
    NSMutableDictionary *keychainDictionary = [[NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey] mutableCopy];
    
    NSMutableDictionary *urlDictionary = [keychainDictionary[baseUrl] mutableCopy];
    keychainDictionary[baseUrl] = urlDictionary;
    
    NSMutableDictionary *cookiesDictionary = [urlDictionary[kSprinklerKeychain_CookiesKey] mutableCopy];
    urlDictionary[kSprinklerKeychain_CookiesKey] = cookiesDictionary;
    
    [cookiesDictionary removeObjectForKey:port];
    
    [keychainDictionary storeToKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey];
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
                newKeychainDictionary[urlKey] = newUrlDictionary;
                
                NSMutableDictionary *newCookiesDictionary = [[newUrlDictionary objectForKey:kSprinklerKeychain_CookiesKey] mutableCopy];
                newUrlDictionary[kSprinklerKeychain_CookiesKey] = newCookiesDictionary;
                
                [newCookiesDictionary removeObjectForKey:portKey];
            }
        }
    }

    if (changed) {
        [newKeychainDictionary storeToKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey];
    }
}

#pragma mark - Cookies

+ (BOOL)isLoginCookieActiveForBaseUrl:(NSString*)baseUrl detectedSprinklerMainVersion:(int*)detectedSprinklerMainVersion
{
    NSArray *cookies = [NetworkUtilities cookiesForURL:[NSURL URLWithString:baseUrl]];
    for (NSHTTPCookie *cookie in cookies) {
        if ([[cookie name] isEqualToString:@"access_token"]) {
            *detectedSprinklerMainVersion = 4;
            return YES;
        }
        if ([[cookie name] isEqualToString:@"login"]) {
            *detectedSprinklerMainVersion = 3;
            return YES;
        }
    }
    
    return NO;
}

+ (void)invalidateLoginForBaseUrl:(NSString*)baseUrl port:(NSString*)port
{
    if (baseUrl) {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSArray *cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:baseUrl]];
        for (NSHTTPCookie *cookie in cookies) {
            [cookieStorage deleteCookie:cookie];
            DLog(@"Deleted cookie: %@", cookie);
        }
        [NetworkUtilities clearKeychainCookieForBaseUrl:baseUrl port:port];
    }
}

+ (void)refreshKeychainCookies
{
    NSString *storePath = [[StorageManager current] persistentStoreLocation];
    // This line should be the first test in this method
    if (![[NSFileManager defaultManager] fileExistsAtPath:storePath]) {
        
        // App was deleted and installed
        [NetworkUtilities clearCookiesFromKeychain];
    }

    [NetworkUtilities importCookiesToKeychain];

    // Clear the session-only cookies from keychain
    [NetworkUtilities clearSessionOnlyCookiesFromKeychain];
}

+ (void)importCookiesToKeychain
{
    // In case the keychain dictionary is empty try to import the cookies from the shared cookie storage
    // Walk through all devices from the db and if it has a persistent cookie, import it into the keychain
    
    NSDictionary *keychainDictionary = [NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CookieDictionaryStorageKey];
    
    if ([keychainDictionary count] == 0) {
        NSArray *remoteSprinklers = [[StorageManager current] getAllSprinklersFromNetwork];
        for (Sprinkler *sprinkler in remoteSprinklers) {
            if ([[NetworkUtilities cookiesForURL:[NSURL URLWithString:sprinkler.address]] count] > 0) {
                [NetworkUtilities saveCookiesForBaseURL:sprinkler.address port:sprinkler.port];
            }
        }
    }
}

@end
