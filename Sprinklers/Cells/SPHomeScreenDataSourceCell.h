//
//  SPHomeScreenDataSourceCell.h
//  Sprinklers
//
//  Created by Fabian Matyas on 10/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Sprinkler;

@interface SPHomeScreenDataSourceCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *dataSourceLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastUpdatedLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusImageView;
@property (weak, nonatomic) Sprinkler *sprinkler;

@end
