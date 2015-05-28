//
//  ProgramCellType5.h
//  Sprinklers
//
//  Created by Fabian Matyas on 23/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"

@interface ProgramCellType5 : UITableViewCell
@property (weak, nonatomic) IBOutlet UISwitch *theSwitch;
@property (weak, nonatomic) IBOutlet UILabel *theTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *theDetailTextLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *theActivityIndicator;

@property (weak, nonatomic) id<CellButtonDelegate> delegate;
@property (assign) BOOL cycleAndSoak;

- (IBAction)onSwitch:(id)sender;

@end
