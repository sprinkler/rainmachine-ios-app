//
//  SPUtils.h
//  Sprinklers
//
//  Created by Fabian Matyas on 15/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CloudUtils : NSObject

+ (NSDictionary*)cloudAccounts;
+ (BOOL)addCloudAccountWithEmail:(NSString*)email password:(NSString*)password;

@end
