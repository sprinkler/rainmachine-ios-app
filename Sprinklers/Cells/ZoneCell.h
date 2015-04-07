//
//  ZoneCell.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 08/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZoneCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *labelTitle;
@property (strong, nonatomic) IBOutlet UILabel *middleLabelTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelAccessory;
@property (strong, nonatomic) IBOutlet UILabel *labelSubtitle;

@end
