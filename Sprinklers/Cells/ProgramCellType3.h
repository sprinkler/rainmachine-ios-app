//
//  ProgramCellType3.h
//  Sprinklers
//
//  Created by Fabian Matyas on 23/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"

@interface ProgramCellType3 : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *theCenteredTextLabel;

@property (weak, nonatomic) IBOutlet UILabel *theTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *theDetailTextLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkmark;
@property (assign) int index;

@property (weak, nonatomic) id<CellButtonDelegate> delegate;
- (IBAction)onCheckMark:(id)sender;

@end
