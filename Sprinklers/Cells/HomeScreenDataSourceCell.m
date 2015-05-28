//
//  SPHomeScreenDataSourceCell.m
//  Sprinklers
//
//  Created by Fabian Matyas on 10/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "HomeScreenDataSourceCell.h"
#import "Sprinkler.h"
#import "Constants.h"

@implementation HomeScreenDataSourceCell

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

- (void)setRainDelayUITo:(BOOL)visible withValue:(int)value
{
    self.lastUpdatedLabel.hidden = visible;
    self.statusImageView.hidden = visible;
    self.wheatherUpdateLabel.hidden = visible;
    self.rainDelayLabel.hidden = !visible;
    
    self.selectionStyle = visible ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;

    self.setRainDelayActivityIndicator.hidden = YES;
    
    if (visible) {
        float selectionFactor = 0.85;
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:selectionFactor * kWateringOrangeButtonColor[0] green:selectionFactor * kWateringOrangeButtonColor[1] blue:selectionFactor * kWateringOrangeButtonColor[2] alpha:1];
        
        int m = (value / 60) % 60;
        int h = (value / (60 * 60)) % 24;
        int d = (value / (60 * 60)) / 24;
        if (d == 0) {
            if (h == 0) {
                // Consider 'labelHours' to be the minutes label
                self.rainDelayLabel.text = [NSString stringWithFormat:@"RAINMACHINE IS PAUSED FOR %d MINUTES\n TAP TO RESUME", m];
            } else {
                self.rainDelayLabel.text = [NSString stringWithFormat:@"RAINMACHINE IS PAUSED FOR %d HOURS %d MINUTES\n TAP TO RESUME", h, m];
            }
        } else {
            self.rainDelayLabel.text = [NSString stringWithFormat:@"RAINMACHINE IS PAUSED FOR %d DAYS %d HOURS %d MINUTES\n TAP TO RESUME", d, h, m];
        }
        
        self.backgroundColor = [UIColor colorWithRed:kWateringOrangeButtonColor[0] green:kWateringOrangeButtonColor[1] blue:kWateringOrangeButtonColor[2] alpha:1];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
}

@end
