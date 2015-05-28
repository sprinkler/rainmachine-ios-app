//
//  UpdateInfo.m
//  Sprinklers
//
//  Created by Fabian Matyas on 30/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "UpdateInfo.h"

@implementation UpdateInfo

+ (UpdateInfo *)createFromJson:(NSDictionary *)jsonObj {
    if (jsonObj) {
        UpdateInfo *info = [[UpdateInfo alloc] init];
        
        info.statusCode = [jsonObj objectForKey:@"statusCode"];
        info.update = [jsonObj objectForKey:@"update"];
        info.current_version = [jsonObj objectForKey:@"current_version"];
        info.the_new_version = [jsonObj objectForKey:@"new_version"];
        info.last_update_check = [jsonObj objectForKey:@"last_update_check"];
        info.update_status = [jsonObj objectForKey:@"update_status"];
        
        return info;
    }
    return nil;
}

@end
