//
//  SettingPassword.m
//  Sprinklers
//
//  Created by Fabian Matyas on 03/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "SettingsPassword.h"

@implementation SettingsPassword

+ (SettingsPassword *)createFromJson:(NSDictionary *)jsonObj {
    if (jsonObj) {
        SettingsPassword *settingsPassword = [[SettingsPassword alloc] init];
        
        settingsPassword.confirmPass = [jsonObj objectForKey:@"confirmPass"];
        settingsPassword.theNewPass = [jsonObj objectForKey:@"newPass"];
        settingsPassword.oldPass = [jsonObj objectForKey:@"oldPass"];
        
        return settingsPassword;
    }
    return nil;
}

@end
