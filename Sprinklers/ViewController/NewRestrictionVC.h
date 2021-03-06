//
//  NewRestrictionVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 28/09/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "CCTBackButtonActionHelper.h"
#import "Protocols.h"

@class RestrictedHoursVC;
@class HourlyRestriction;

@interface NewRestrictionVC : BaseLevel2ViewController <UITableViewDelegate, UITableViewDataSource, CellButtonDelegate, WeekdaysVCDelegate, TimePickerDelegate, SprinklerResponseProtocol, CCTBackButtonActionHelperProtocol>

@property (weak, nonatomic) RestrictedHoursVC *parent;
@property (nonatomic, copy) HourlyRestriction *restriction;
@property (copy, nonatomic) HourlyRestriction *restrictionCopyBeforeSave;
@property (assign) int restrictionIndex;
@property (assign) BOOL showInitialUnsavedAlert;

- (IBAction)onDiscard:(id)sender;
- (IBAction)onSave:(id)sender;

@end
