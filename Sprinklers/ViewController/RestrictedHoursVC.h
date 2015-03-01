//
//  RestrictedHoursVC.h
//  Sprinklers
//
//  Created by Adrian Manolache on 18/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class RestrictionsVC;
@class HourlyRestriction;

@interface RestrictedHoursVC : BaseLevel2ViewController <UITableViewDelegate, UITableViewDataSource, SprinklerResponseProtocol>

@property (weak, nonatomic) RestrictionsVC *parent;

@property (strong, nonatomic) NSArray *hourlyRestrictions;

- (void)setUnsavedRestriction:(HourlyRestriction*)restriction withIndex:(int)i;

@end
