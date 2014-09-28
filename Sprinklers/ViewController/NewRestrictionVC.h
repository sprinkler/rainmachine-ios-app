//
//  NewRestrictionVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 28/09/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class RestrictedHoursVC;

@interface NewRestrictionVC : BaseLevel2ViewController <UITableViewDelegate, UITableViewDataSource, CellButtonDelegate, WeekdaysVCDelegate, TimePickerDelegate, SprinklerResponseProtocol>

@property (weak, nonatomic) RestrictedHoursVC *parent;

- (IBAction)onDiscard:(id)sender;
- (IBAction)onSave:(id)sender;

@end
