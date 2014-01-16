//
//  SPHomeScreenDataSourceCell.m
//  Sprinklers
//
//  Created by Fabian Matyas on 10/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "HomeScreenDataSourceCell.h"
#import "Sprinkler.h"

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

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  self.statusImageView.center = CGPointMake(self.statusImageView.center.x, self.frame.size.height / 2 );
  self.dataSourceLabel.center = CGPointMake(self.dataSourceLabel.center.x, self.frame.size.height / 2 - self.dataSourceLabel.frame.size.height / 2);
  self.lastUpdatedLabel.center = CGPointMake(self.lastUpdatedLabel.center.x, self.frame.size.height / 2 + self.lastUpdatedLabel.frame.size.height / 2);

  self.statusImageView.image = [UIImage imageNamed:(self.sprinkler.lastError == nil) ? @"icon_status_ok" : @"icon_status_warning"];
}


@end
