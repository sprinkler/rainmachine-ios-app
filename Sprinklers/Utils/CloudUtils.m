//
//  SPUtils.m
//  Sprinklers
//
//  Created by Fabian Matyas on 15/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "CloudUtils.h"
#import "NSDictionary+Keychain.h"
#import "Constants.h"

@implementation CloudUtils

#pragma mark - Cloud Keychain

+ (NSDictionary*)cloudAccounts
{
    NSDictionary *keychainDictionary = [NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CloudAccount];
    return keychainDictionary;
}

+ (BOOL)addCloudAccountWithEmail:(NSString*)email password:(NSString*)password
{
    NSMutableDictionary *keychainDictionary = [[NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CloudAccount] mutableCopy];
    if (!keychainDictionary) {
        keychainDictionary = [NSMutableDictionary dictionary];
    }
    
    if (keychainDictionary[email] == nil) {
        keychainDictionary[email] = password;
        [keychainDictionary storeToKeychainWithKey:kSprinklerKeychain_CloudAccount];
        
        return YES;
    }
    
    return NO;
}

+ (void)deleteCloudAccountWithEmail:(NSString*)email
{
    NSMutableDictionary *keychainDictionary = [[NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CloudAccount] mutableCopy];
    [keychainDictionary removeObjectForKey:email];
    
    [keychainDictionary storeToKeychainWithKey:kSprinklerKeychain_CloudAccount];
}

@end
