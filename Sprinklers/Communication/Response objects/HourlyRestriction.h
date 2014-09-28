//
//  HourlyRestriction.h
//  Sprinklers
//
//  Created by Fabian Matyas on 27/09/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HourlyRestriction : NSObject

@property (nonatomic, assign) NSNumber *uid;
@property (nonatomic, strong) NSString *interval;
@property (nonatomic, assign) NSNumber *dayStartMinute;
@property (nonatomic, assign) NSNumber *minuteDuration;
@property (nonatomic, retain) NSString *weekDays;

@end
