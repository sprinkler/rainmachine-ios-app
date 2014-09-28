//
//  RestrictionsSwitchCell.h
//  Sprinklers
//
//  Created by Fabian Matyas on 26/09/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"

@interface RestrictionsSwitchCell : UITableViewCell

@property (assign, nonatomic) NSInteger uid;
@property (weak, nonatomic) id<CellButtonDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *restrictionNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *restrictionDescriptionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *restrictionEnabledSwitch;

- (IBAction)onSwitch:(id)sender;

@end
