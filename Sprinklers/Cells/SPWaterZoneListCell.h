//
//  SPWaterZoneListCell.h
//  Sprinklers
//
//  Created by Fabian Matyas on 14/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPWaterNowTableViewController;

@interface SPWaterZoneListCell : UITableViewCell

@property (weak, nonatomic) SPWaterNowTableViewController *delegate;
@property (weak, nonatomic) NSNumber *id;
@property (weak, nonatomic) NSNumber *counter;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *zoneNameLabel;
@property (weak, nonatomic) IBOutlet UISwitch *onOffSwitch;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

- (IBAction)onSwitch:(id)sender;

@end
