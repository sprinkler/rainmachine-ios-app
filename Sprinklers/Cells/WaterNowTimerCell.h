//
//  WaterNowTimerCell.h
//  Sprinklers
//
//  Created by Fabian Matyas on 18/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WaterNowTimerCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (weak, nonatomic) IBOutlet UIButton *upButton;
@property (weak, nonatomic) IBOutlet UIButton *downButton;

@end
