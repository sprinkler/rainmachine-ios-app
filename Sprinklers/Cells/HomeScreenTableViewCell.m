//
//  SPHomeScreenTableViewCell.m
//  Sprinklers
//
//  Created by Fabian Matyas on 10/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "HomeScreenTableViewCell.h"
#import "Constants.h"
#import "Utils.h"

@implementation HomeScreenTableViewCell

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
    int w = 120 * self.waterPercentage;
    
    float padding = 0;
    self.daylabel.center = CGPointMake(self.daylabel.center.x, roundf(self.frame.size.height / 2 - self.daylabel.frame.size.height / 2 - padding));
    self.temperatureLabel.frame = CGRectMake(self.daylabel.frame.origin.x, roundf(self.frame.size.height / 2 + padding), evenValue(self.temperatureLabel.frame.size.width), self.temperatureLabel.frame.size.height);
    self.percentageLabel.center = CGPointMake(self.percentageLabel.center.x, roundf(self.frame.size.height / 2));
    self.weatherImage.center = CGPointMake(self.weatherImage.center.x, self.percentageLabel.center.y);
    self.percentageNotAvailableLabel.center = CGPointMake(30, self.weatherImage.center.y);
    
    self.waterImage.frame = CGRectMake(0, 0, w, self.waterImage.frame.size.height);
    self.waterWavesImageView.frame = CGRectMake(self.waterImage.frame.origin.x + self.waterImage.frame.size.width,
                                                0,
                                                waterWavesWidth,
                                                self.waterWavesImageView.frame.size.height);
    
    [self.temperatureLabelPart2 sizeToFit];
    [self.temperatureLabelPart4 sizeToFit];
    
    const float yPadding = 6;
    float y = self.daylabel.frame.origin.y + self.daylabel.frame.size.height + kWheatherValueFontSize / 2 + yPadding;
    
    int paddingPart2 = [self.temperatureLabelPart2.font.fontName isEqualToString:kCustomRMFontName] ? kXCorrectionbetweenCustomAndNormalWheatherFont : 0;
    self.temperatureLabelPart2.frame = CGRectMake(paddingPart2 + self.daylabel.frame.origin.x,
                                                  y - evenValue(self.temperatureLabelPart2.frame.size.height / 2),
                                                  evenValue(self.temperatureLabelPart2.frame.size.width),
                                                  self.temperatureLabelPart2.frame.size.height);
    
    int paddingPart4 = [self.temperatureLabelPart4.font.fontName isEqualToString:kCustomRMFontName] ? kXCorrectionbetweenCustomAndNormalWheatherFont : 0;
    self.temperatureLabelPart4.frame = CGRectMake(paddingPart4 + self.temperatureLabelPart2.frame.origin.x + self.temperatureLabelPart2.frame.size.width,
                                                  y - evenValue(self.temperatureLabelPart4.frame.size.height / 2),
                                                  evenValue(self.temperatureLabelPart4.frame.size.width),
                                                  self.temperatureLabelPart4.frame.size.height);
}

@end
