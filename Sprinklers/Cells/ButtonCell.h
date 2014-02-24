//
//  ButtonCell.h
//  Sprinklers
//
//  Created by Fabian Matyas on 23/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"

@class ColoredBackgroundButton;

@interface ButtonCell : UITableViewCell

@property (weak, nonatomic) IBOutlet ColoredBackgroundButton *button;
@property (weak, nonatomic) id<CellButtonDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *buttonActivityIndicator;

- (IBAction)onRunNow:(id)sender;

@end
