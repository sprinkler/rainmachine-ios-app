//
//  ProgramCellType2.m
//  Sprinklers
//
//  Created by Fabian Matyas on 23/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProgramCellType2.h"

@implementation ProgramCellType2

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onSwitch:(id)sender {
    [_delegate onCellSwitch:self];
}

@end
