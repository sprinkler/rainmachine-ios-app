//
//  NSDictionary+Keychain.m
//  Sprinklers
//
//  Created by Fabian Matyas on 23/05/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "NSDictionary+Keychain.h"

@implementation NSDictionary (Keychain)

-(void) storeToKeychainWithKey:(NSString *)aKey {
    // serialize dict
    NSString *error = nil;
//    NSData *serializedDictionary = [NSPropertyListSerialization dataFromPropertyList:self format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
    NSData *serializedDictionary = [NSKeyedArchiver archivedDataWithRootObject:self];
    
    // encrypt in keychain
    if(!error) {
        // first, delete potential existing entries with this key (it won't auto update)
        [self deleteFromKeychainWithKey:aKey];
        
        // setup keychain storage properties
        NSDictionary *storageQuery = @{
                                       (id)kSecAttrAccount:    aKey,
                                       (id)kSecValueData:      serializedDictionary,
                                       (id)kSecClass:          (id)kSecClassGenericPassword,
                                       (id)kSecAttrAccessible: (id)kSecAttrAccessibleWhenUnlocked
                                       };
        OSStatus osStatus = SecItemAdd((CFDictionaryRef)storageQuery, nil);
        if(osStatus != noErr) {
            DLog(@"Keychain store error: %d", osStatus);
        }
    }
}


+(NSDictionary *) dictionaryFromKeychainWithKey:(NSString *)aKey {
    // setup keychain query properties
    NSDictionary *readQuery = @{
                                (id)kSecAttrAccount: aKey,
                                (id)kSecReturnData: (id)kCFBooleanTrue,
                                (id)kSecClass:      (id)kSecClassGenericPassword
                                };
    
    NSData *serializedDictionary = nil;
    OSStatus osStatus = SecItemCopyMatching((CFDictionaryRef)readQuery, (CFTypeRef *)&serializedDictionary);
    if(osStatus == noErr) {
        // deserialize dictionary
        NSString *error = nil;
//        NSDictionary *storedDictionary = [NSPropertyListSerialization propertyListFromData:serializedDictionary mutabilityOption:NSPropertyListImmutable format:nil errorDescription:&error];
        NSDictionary *storedDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:serializedDictionary];
        if(error) {
            DLog(@"Keychain read error: %@", error);
        }
        return storedDictionary;
    }
    else {
        // do something with error
        return nil;
    }
}


-(void) deleteFromKeychainWithKey:(NSString *)aKey {
    // setup keychain query properties
    NSDictionary *deletableItemsQuery = @{
                                          (id)kSecAttrAccount:        aKey,
                                          (id)kSecClass:              (id)kSecClassGenericPassword,
                                          (id)kSecMatchLimit:         (id)kSecMatchLimitAll,
                                          (id)kSecReturnAttributes:   (id)kCFBooleanTrue
                                          };
    
    NSArray *itemList = nil;
    OSStatus osStatus = SecItemCopyMatching((CFDictionaryRef)deletableItemsQuery, (CFTypeRef *)&itemList);
    // each item in the array is a dictionary
    for (NSDictionary *item in itemList) {
        NSMutableDictionary *deleteQuery = [item mutableCopy];
        [deleteQuery setValue:(id)kSecClassGenericPassword forKey:(id)kSecClass];
        // do delete
        osStatus = SecItemDelete((CFDictionaryRef)deleteQuery);
        if(osStatus != noErr) {
            DLog(@"Keychain delete error: %d", osStatus);
        }
        [deleteQuery release];
    }
}

@end
