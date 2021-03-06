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

+ (void)resetKeychain
{
    [@{} storeToKeychainWithKey:kSprinklerKeychain_CloudAccount];
}

+ (NSDictionary*)cloudAccounts
{
    NSDictionary *keychainDictionary = [NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CloudAccount];
    return keychainDictionary;
}

+ (NSString*)firstCloudAccount {
    NSMutableArray *cloudEmails = [[self cloudAccounts].allKeys mutableCopy];
    if (!cloudEmails.count) return nil;
    [cloudEmails sortUsingSelector:@selector(compare:)];
    return cloudEmails.firstObject;
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

+ (BOOL)updateCloudAccountWithEmail:(NSString*)email newPassword:(NSString*)newPassword {
    NSMutableDictionary *keychainDictionary = [[NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CloudAccount] mutableCopy];
    if (!keychainDictionary) return NO;
    if (keychainDictionary[email] == nil) return NO;
    
    keychainDictionary[email] = newPassword;
    [keychainDictionary storeToKeychainWithKey:kSprinklerKeychain_CloudAccount];
    
    return NO;
}

+ (BOOL)existsCloudAccountWithEmail:(NSString*)email {
    NSDictionary *keychainDictionary = [NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CloudAccount];
    return (keychainDictionary[email] != nil);
}

+ (NSString*)passwordForCloudAccountWithEmail:(NSString*)email {
    if (!email.length) return nil;
    NSDictionary *keychainDictionary = [NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CloudAccount];
    return keychainDictionary[email];
}

+ (void)deleteCloudAccountWithEmail:(NSString*)email
{
    NSMutableDictionary *keychainDictionary = [[NSDictionary dictionaryFromKeychainWithKey:kSprinklerKeychain_CloudAccount] mutableCopy];
    [keychainDictionary removeObjectForKey:email];
    
    [keychainDictionary storeToKeychainWithKey:kSprinklerKeychain_CloudAccount];
}

@end
