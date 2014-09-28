//
//  RestrictionsCheckCell.h
//  Sprinklers
//
//  Created by Fabian Matyas on 28/09/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"

@interface RestrictionsCheckCell : UITableViewCell

@property (assign, nonatomic) NSInteger uid;
@property (weak, nonatomic) id<CellButtonDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *restrictionNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *restrictionCenteredNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *restrictionDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkmarkButton;

- (IBAction)onCheck:(id)sender;

@end
