//
//  ProgramListCell.h
//  Sprinklers
//
//  Created by Fabian Matyas on 25/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgramListCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *activeStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *theTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *theDetailTextLabel;

@end
