//
//  SPHomeScreenTableViewCell.m
//  Sprinklers
//
//  Created by Fabian Matyas on 10/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SPHomeScreenTableViewCell.h"

@implementation SPHomeScreenTableViewCell

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

- (void)layoutSubviews
{
  [super layoutSubviews];
  int w = 120 * self.waterPercentage;
  if (w % 2 != 0) {
    w++;
  }
  
  self.waterImage.frame = CGRectMake(0, 0, w, self.waterImage.frame.size.height);
  
  float padding = 0;
  self.daylabel.center = CGPointMake(self.daylabel.center.x, self.frame.size.height / 2 - self.daylabel.frame.size.height / 2 - padding);
  self.temperatureLabel.center = CGPointMake(self.daylabel.center.x, self.frame.size.height / 2 + self.temperatureLabel.frame.size.height / 2 + padding);
  self.weatherImage.center = CGPointMake(self.weatherImage.center.x, self.frame.size.height / 2);
  self.percentageLabel.center = CGPointMake(self.percentageLabel.center.x, self.frame.size.height / 2);
}

@end
