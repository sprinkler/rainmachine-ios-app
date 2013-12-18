//
//  WaterNowStartCell.m
//  Sprinklers
//
//  Created by Fabian Matyas on 18/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "WaterNowStartCell.h"

@implementation WaterNowStartCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self.startButton addTarget:self action:@selector(onStart:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
