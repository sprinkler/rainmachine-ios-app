//
//  SPHomeScreenTableViewCell.h
//  Sprinklers
//
//  Created by Fabian Matyas on 10/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomeScreenTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *waterImage;
@property (weak, nonatomic) IBOutlet UILabel *notAvailableLabel;
@property (weak, nonatomic) IBOutlet UIImageView *weatherImage;
@property (weak, nonatomic) IBOutlet UILabel *daylabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (assign, nonatomic) float waterPercentage;
@property (weak, nonatomic) IBOutlet UILabel *percentageLabel;
@property (weak, nonatomic) IBOutlet UIImageView *waterWavesImageView;

@end
