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
  float waterWavesWidth = (self.waterWavesImageView.image.size.width * self.frame.size.height) / self.waterWavesImageView.image.size.height;
  int w = MAX(waterWavesWidth, (120 * self.waterPercentage) - waterWavesWidth);
  
  float padding = 0;
  self.daylabel.center = CGPointMake(self.daylabel.center.x, self.frame.size.height / 2 - self.daylabel.frame.size.height / 2 - padding);
  self.temperatureLabel.center = CGPointMake(self.daylabel.center.x, self.frame.size.height / 2 + self.temperatureLabel.frame.size.height / 2 + padding);
  self.percentageLabel.center = CGPointMake(self.percentageLabel.center.x, self.frame.size.height / 2);
  self.weatherImage.center = CGPointMake(self.weatherImage.center.x, self.frame.size.height / 2);
  
  self.waterImage.frame = CGRectMake(0, 0, w, self.waterImage.frame.size.height);
  self.waterWavesImageView.frame = CGRectMake(self.waterImage.frame.origin.x + self.waterImage.frame.size.width,
                                              0,
                                              waterWavesWidth,
                                              self.waterWavesImageView.frame.size.height);
}

@end
