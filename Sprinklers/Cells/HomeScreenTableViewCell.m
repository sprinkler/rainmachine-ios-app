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
    
    if (self.waterWavesImageView.image) {
        const int kDayLabelPaddingX = 75;
        const int kWaterImagePaddingX = 140;
        float waterWavesWidth = (self.waterWavesImageView.image.size.width * self.frame.size.height) / self.waterWavesImageView.image.size.height;
        CGFloat paddingBetweenWaterAndWeatherImage = 5;
        CGFloat maxWaterImageWidth = self.contentView.frame.size.width - kWaterImagePaddingX;
        int w = maxWaterImageWidth * self.waterPercentage;
        
        float padding = 0;
        self.daylabel.center = CGPointMake(self.contentView.frame.size.width - kDayLabelPaddingX + self.daylabel.frame.size.width / 2, roundf(self.frame.size.height / 2 - self.daylabel.frame.size.height / 2 - padding));
        self.temperatureLabel.frame = CGRectMake(self.daylabel.frame.origin.x, roundf(self.frame.size.height / 2 + padding), evenValue(self.temperatureLabel.frame.size.width), self.temperatureLabel.frame.size.height);
        self.percentageLabel.center = CGPointMake(self.percentageLabel.center.x, roundf(self.frame.size.height / 2));
        self.percentageNotAvailableLabel.center = CGPointMake(30, self.weatherImage.center.y);
        
        self.waterImage.frame = CGRectMake(0, 0, w, self.waterImage.frame.size.height);
        self.weatherImage.center = CGPointMake(self.waterImage.frame.origin.x + maxWaterImageWidth + self.weatherImage.frame.size.width / 2 + paddingBetweenWaterAndWeatherImage,
                                               self.percentageLabel.center.y);
        self.waterWavesImageView.frame = CGRectMake(self.waterImage.frame.origin.x + self.waterImage.frame.size.width,
                                                    0,
                                                    waterWavesWidth,
                                                    self.waterWavesImageView.frame.size.height);
        
        [self.temperatureLabelPart2 sizeToFit];
        [self.temperatureLabelPart4 sizeToFit];
        
        const float yPadding = 6;
        float y = self.daylabel.frame.origin.y + self.daylabel.frame.size.height + kWheatherValueFontSize / 2 + yPadding;
        
        BOOL mintValid = ![self.temperatureLabelPart4.font.fontName isEqualToString:kCustomRMFontName];
        BOOL maxtValid = ![self.temperatureLabelPart2.font.fontName isEqualToString:kCustomRMFontName];

//        // Right aligned
//        CGFloat distanceBetweenTemperatures = 5;
//        if (!mintValid) {
//            if (!maxtValid) {
//                distanceBetweenTemperatures = -1;
//            } else {
//                distanceBetweenTemperatures = -2;
//            }
//        } else {
//            if (!maxtValid) {
//                distanceBetweenTemperatures = 6;
//            }
//        }
//        
//        CGFloat width4 = evenValue(self.temperatureLabelPart4.frame.size.width);
//        int paddingPart4 = !mintValid ? kXCorrectionbetweenCustomAndNormalWheatherFont : 0;
//        self.temperatureLabelPart4.frame = CGRectMake(-paddingPart4 + self.daylabel.frame.origin.x + self.daylabel.frame.size.width - width4,
//                                                      y - evenValue(self.temperatureLabelPart4.frame.size.height / 2),
//                                                      width4,
//                                                      self.temperatureLabelPart4.frame.size.height);
//        
//        CGFloat width2 = evenValue(self.temperatureLabelPart2.frame.size.width);
//        int paddingPart2 = !maxtValid ? kXCorrectionbetweenCustomAndNormalWheatherFont : 0;
//        self.temperatureLabelPart2.frame = CGRectMake(-paddingPart2 + self.temperatureLabelPart4.frame.origin.x - width2 - distanceBetweenTemperatures,
//                                                      y - evenValue(self.temperatureLabelPart2.frame.size.height / 2),
//                                                      width2,
//                                                      self.temperatureLabelPart2.frame.size.height);

        // Left aligned
        CGFloat distanceBetweenTemperatures = 5;
        if (!mintValid) {
            if (!maxtValid) {
                distanceBetweenTemperatures = 1;
            } else {
                distanceBetweenTemperatures = 4;
            }
        } else {
            if (!maxtValid) {
                distanceBetweenTemperatures = 2;
            }
        }

        CGFloat width2 = evenValue(self.temperatureLabelPart2.frame.size.width);
        int paddingPart2 = !maxtValid ? -kXCorrectionbetweenCustomAndNormalWheatherFont : 0;
        self.temperatureLabelPart2.frame = CGRectMake(-paddingPart2 + self.daylabel.frame.origin.x,
                                                      y - evenValue(self.temperatureLabelPart2.frame.size.height / 2),
                                                      width2,
                                                      self.temperatureLabelPart2.frame.size.height);
        CGFloat width4 = evenValue(self.temperatureLabelPart4.frame.size.width);
        int paddingPart4 = !mintValid ? -kXCorrectionbetweenCustomAndNormalWheatherFont : 0;
        self.temperatureLabelPart4.frame = CGRectMake(-paddingPart4 + self.temperatureLabelPart2.frame.origin.x + self.temperatureLabelPart2.frame.size.width + distanceBetweenTemperatures,
                                                      y - evenValue(self.temperatureLabelPart4.frame.size.height / 2),
                                                      width4,
                                                      self.temperatureLabelPart4.frame.size.height);
    }
}

@end
