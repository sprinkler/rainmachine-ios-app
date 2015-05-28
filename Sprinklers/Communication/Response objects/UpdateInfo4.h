//
//  UpdateInfo.h
//  Sprinklers
//
//  Created by Fabian Matyas on 30/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    API4_UpdateStatusIdle   = 1,
    API4_UpdateStatusChecking,
    API4_UpdateStatusDownloading,
    API4_UpdateStatusUpgrading,
    API4_UpdateStatusError,
    API4_UpdateStatusReboot
} API4_UpdateStatus;

@interface UpdateInfo4 : NSObject

@property (nonatomic, strong) NSNumber *updateStatus;
@property (nonatomic, strong) NSString *lastUpdateCheck;
@property (nonatomic, strong) NSNumber *update;
@property (nonatomic, strong) NSArray *packageDetails;

+ (UpdateInfo4 *)createFromJson:(NSDictionary *)jsonObj;

@end
