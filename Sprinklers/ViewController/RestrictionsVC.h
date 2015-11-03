//
//  RestrictionsVC.h
//  Sprinklers
//
//  Created by Adrian Manolache on 07/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class SettingsVC;
@class HourlyRestriction;

@interface RestrictionsVC : BaseLevel2ViewController <UITableViewDelegate, UITableViewDataSource, WeekdaysVCDelegate, MonthsVCDelegate, PickerVCDelegate, CellButtonDelegate, SprinklerResponseProtocol>

@property (weak, nonatomic) SettingsVC *parent;

- (NSString*)daysDescriptionForHourlyRestriction:(HourlyRestriction*)restriction;
- (NSString*)timeDescriptionForHourlyRestriction:(HourlyRestriction*)restriction;
- (NSString*)descriptionForHourlyRestriction:(HourlyRestriction*)restriction;

@end
