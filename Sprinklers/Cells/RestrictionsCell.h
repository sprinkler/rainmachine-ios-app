//
//  RestrictionsCell.h
//  Sprinklers
//
//  Created by Adrian Manolache on 14/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RestrictionsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *restrictionNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *restrictionCenteredNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *restrictionDescriptionLabel;

@end
