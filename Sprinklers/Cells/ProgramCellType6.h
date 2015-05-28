//
//  ProgramCellType6.h
//  Sprinklers
//
//  Created by Fabian Matyas on 23/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"

@class ProgramWateringTimes4;

@interface ProgramCellType6 : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *theTextLabel;
@property (weak, nonatomic) IBOutlet UISwitch *theSwitch;

@property (weak, nonatomic) id<CellButtonDelegate> delegate;
@property (strong, nonatomic) ProgramWateringTimes4 *programWateringTime;

- (IBAction)onSwitch:(id)sender;

@end
