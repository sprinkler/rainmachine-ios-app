//
//  RainSensitivityGraphMonthView.m
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RainSensitivityGraphMonthView.h"
#import "Constants.h"

#pragma mark -

@interface RainSensitivityGraphMonthView ()

- (void)drawValues:(NSArray*)values withColor:(UIColor*)color inContext:(CGContextRef)context;

@end

#pragma mark -

@implementation RainSensitivityGraphMonthView

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;
    
    _graphValuesDivider = 1.0;
    
    return self;
}

- (void)draw {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawValues:self.graphBackgroundValues withColor:self.graphBackgroundColor inContext:context];
    [self drawValues:self.graphForegroundValues withColor:self.graphForegroundColor inContext:context];
}

static CGPoint midPointForPoints(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
}

static CGPoint controlPointForPoints(CGPoint p1, CGPoint p2) {
    CGPoint controlPoint = midPointForPoints(p1, p2);
    CGFloat diffY = abs(p2.y - controlPoint.y);
    
    if (p1.y < p2.y)
        controlPoint.y += diffY;
    else if (p1.y > p2.y)
        controlPoint.y -= diffY;
    
    return controlPoint;
}

- (void)drawValues:(NSArray*)values withColor:(UIColor*)color inContext:(CGContextRef)context {
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    CGFloat stepWidth = self.frame.size.width / (values.count - 1);
    CGFloat stepX = 0.0;
    CGFloat maxValue = (self.maxValue == 0.0 ? 2.0 : self.maxValue);
    CGFloat valueDivider = maxValue * self.graphValuesDivider;
    CGPoint previousPoint = CGPointZero;
    
    BOOL firstPoint = YES;
    
    for (id value in values) {
        double doubleValue = 0.0;
        if (value != [NSNull null]) doubleValue = ((NSNumber*)value).doubleValue;
        
        CGFloat heightY = self.frame.size.height * doubleValue / valueDivider;
        CGFloat stepY = self.frame.size.height - heightY;
        CGFloat roundedStepX = ceil(stepX);
        
        if (firstPoint) {
            CGContextMoveToPoint(context, roundedStepX, stepY);
            previousPoint = CGPointMake(roundedStepX, stepY);
        }
        else {
            CGPoint point = CGPointMake(roundedStepX, stepY);
            CGPoint midPoint = midPointForPoints(previousPoint, point);
            CGPoint controlPoint1 = controlPointForPoints(midPoint, previousPoint);
            CGPoint controlPoint2 = controlPointForPoints(midPoint, point);
            
            CGContextAddQuadCurveToPoint(context, controlPoint1.x, controlPoint1.y, midPoint.x, midPoint.y);
            CGContextAddQuadCurveToPoint(context, controlPoint2.x, controlPoint2.y, point.x, point.y);
            
            previousPoint = point;
        }
            
        stepX += stepWidth;
        
        firstPoint = NO;
    }
    
    CGContextAddLineToPoint(context, ceil(stepX - stepWidth), self.frame.size.height + 1.0);
    CGContextAddLineToPoint(context, 0.0, self.frame.size.height + 1.0);
    
    CGContextClosePath(context);
    CGContextFillPath(context);
}

@end
