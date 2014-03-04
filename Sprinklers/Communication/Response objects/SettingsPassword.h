//
//  SettingPassword.h
//  Sprinklers
//
//  Created by Fabian Matyas on 03/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsPassword : NSObject

@property (nonatomic, strong) NSString *confirmPass;
@property (nonatomic, strong) NSString *theNewPass;
@property (nonatomic, strong) NSString *oldPass;

@end
