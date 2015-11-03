//
//  GraphView.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphView.h"
#import "GraphStyle.h"

@implementation GraphView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.graphStyle plotInRect:self.bounds context:context];
}

@end
