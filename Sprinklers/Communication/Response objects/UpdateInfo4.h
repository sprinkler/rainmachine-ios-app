//
//  UpdateInfo.h
//  Sprinklers
//
//  Created by Fabian Matyas on 30/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UpdateInfo4 : NSObject

@property (nonatomic, strong) NSNumber *updateStatus;
@property (nonatomic, strong) NSString *lastUpdateCheck;
@property (nonatomic, strong) NSNumber *update;
@property (nonatomic, strong) NSArray *packageDetails;

+ (UpdateInfo4 *)createFromJson:(NSDictionary *)jsonObj;

@end
