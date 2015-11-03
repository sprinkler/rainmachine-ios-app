//
//  RMSwitch.m
//  Sprinklers
//
//  Created by Fabian Matyas on 18/06/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RMSwitch.h"
#import "WaterZoneListCell.h"

@implementation RMSwitch

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.isUnderUserTracking = NO;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        self.isUnderUserTracking = NO;
    }
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.isUnderUserTracking = YES;
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.isUnderUserTracking = NO;
    [super touchesEnded:touches withEvent:event];
    
    [self.cell onSwitch:self];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.isUnderUserTracking = NO;
    [super touchesCancelled:touches withEvent:event];
    
    [self.cell onSwitch:self];
}

@end
