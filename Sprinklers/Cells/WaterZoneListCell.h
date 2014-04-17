//
//  SPWaterZoneListCell.h
//  Sprinklers
//
//  Created by Fabian Matyas on 14/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WaterNowVC;
@class WaterNowZone;

@interface WaterZoneListCell : UITableViewCell

@property (weak, nonatomic) WaterNowVC *delegate;
@property (weak, nonatomic) WaterNowZone *zone;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *zoneNameLabel;
@property (weak, nonatomic) IBOutlet UISwitch *onOffSwitch;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabelMultipartBottom;
@property (weak, nonatomic) IBOutlet UILabel *timeLabelMultipartTop;

- (IBAction)onSwitch:(id)sender;

@end
