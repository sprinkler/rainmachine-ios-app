//
//  SPUtils.h
//  Sprinklers
//
//  Created by Fabian Matyas on 15/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CloudUtils : NSObject

+ (void)resetKeychain;
+ (NSDictionary*)cloudAccounts;
+ (NSString*)firstCloudAccount;
+ (BOOL)addCloudAccountWithEmail:(NSString*)email password:(NSString*)password;
+ (BOOL)updateCloudAccountWithEmail:(NSString*)email newPassword:(NSString*)newPassword;
+ (BOOL)existsCloudAccountWithEmail:(NSString*)email;
+ (NSString*)passwordForCloudAccountWithEmail:(NSString*)email;
+ (void)deleteCloudAccountWithEmail:(NSString*)email;

@end
