//
//  HourlyRestriction.h
//  Sprinklers
//
//  Created by Fabian Matyas on 27/09/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HourlyRestriction : NSObject

@property (nonatomic, strong) NSNumber *uid;
@property (nonatomic, strong) NSString *interval;
@property (nonatomic, strong) NSNumber *dayStartMinute;
@property (nonatomic, strong) NSNumber *minuteDuration;
@property (nonatomic, strong) NSString *weekDays;

@end
