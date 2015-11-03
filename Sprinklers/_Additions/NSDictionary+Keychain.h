//
//  NSDictionary+Keychain.h
//  Sprinklers
//
//  Created by Fabian Matyas on 23/05/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Keychain)

-(void) deleteFromKeychainWithKey:(NSString *)aKey;
+(NSDictionary *) dictionaryFromKeychainWithKey:(NSString *)aKey;
-(void) storeToKeychainWithKey:(NSString *)aKey;

@end
