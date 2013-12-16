//
//  SPWaterZoneListCell.m
//  Sprinklers
//
//  Created by Fabian Matyas on 14/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SPWaterZoneListCell.h"
#import "SPWaterNowTableViewController.h"

@implementation SPWaterZoneListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onSwitch:(id)sender {
  [self.delegate toggleWatering:sender onZoneWithId:self.id andCounter:self.counter];
}

@end
