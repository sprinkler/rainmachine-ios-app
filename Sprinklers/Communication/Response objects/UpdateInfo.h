//
//  UpdateInfo.h
//  Sprinklers
//
//  Created by Fabian Matyas on 30/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UpdateInfo : NSObject

@property (nonatomic, strong) NSNumber *statusCode;
@property (nonatomic, strong) NSNumber *update;
@property (nonatomic, strong) NSString *current_version;
@property (nonatomic, strong) NSString *the_new_version;
@property (nonatomic, strong) NSString *last_update_check;
@property (nonatomic, strong) NSNumber *update_status;

+ (UpdateInfo *)createFromJson:(NSDictionary *)jsonObj;

@end
