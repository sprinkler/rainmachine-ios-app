//
//  ProgramCellType1.h
//  Sprinklers
//
//  Created by Fabian Matyas on 23/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"

@interface ProgramCellType1 : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *theTextField;

@property (weak, nonatomic) id<CellButtonDelegate> delegate;

@end
