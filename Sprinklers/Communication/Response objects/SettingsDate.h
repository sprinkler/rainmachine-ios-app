//
//  SettingsDate.h
//  Sprinklers
//
//  Created by Fabian Matyas on 03/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsDate : NSObject

@property (nonatomic, strong) NSString *appDate;
@property (nonatomic, strong) NSNumber *time_format;
@property (nonatomic, strong) NSNumber *am_pm;

@end
