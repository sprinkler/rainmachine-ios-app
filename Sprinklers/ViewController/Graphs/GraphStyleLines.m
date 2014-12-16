//
//  GraphStyleLines.m
//  Sprinklers
//
//  Created by Istvan Sipos on 10/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphStyleLines.h"
#import "GraphDescriptor.h"
#import "GraphVisualAppearanceDescriptor.h"
#import "GraphDisplayAreaDescriptor.h"

@implementation GraphStyleLines

- (void)plotGraphInRect:(CGRect)rect context:(CGContextRef)context {
    CGContextSaveGState(context);
    
    NSInteger maxValue = 0;
    for (NSNumber *value in self.values) {
        if (value.integerValue > maxValue) maxValue = value.integerValue;
    }
    
    CGContextSetStrokeColorWithColor(context, self.graphDescriptor.displayAreaDescriptor.graphDisplayColor.CGColor);
    CGContextSetFillColorWithColor(context, self.graphDescriptor.visualAppearanceDescriptor.backgroundColor.CGColor);
    CGContextSetLineWidth(context, 1.0 / [UIScreen mainScreen].scale);
    
    CGFloat graphCirclesRadius = self.graphDescriptor.displayAreaDescriptor.graphCirclesRadius;
    
    CGFloat graphTopPadding = self.graphDescriptor.displayAreaDescriptor.graphBarsTopPadding + self.graphDescriptor.displayAreaDescriptor.valuesDisplayHeight;
    CGFloat graphBottomPadding = self.graphDescriptor.displayAreaDescriptor.graphBarsBottomPadding - 1.0;
    CGFloat displayHeight = rect.size.height - graphTopPadding - graphBottomPadding;
    CGFloat displayWidth = rect.size.width - self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding - self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
    
    CGFloat barDisplayWidth = displayWidth / self.values.count;
    CGFloat barCenterX = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding + barDisplayWidth / 2.0;
    CGFloat oldBarCenterX = barCenterX;
    
    BOOL firstPoint = YES;
    for (NSNumber *value in self.values) {
        CGFloat barSizeHeight = value.doubleValue / 100.0 * displayHeight;
        CGFloat barCenterY = rect.size.height - barSizeHeight - graphBottomPadding;
        
        if (firstPoint) CGContextMoveToPoint(context, round(barCenterX), round(barCenterY));
        else CGContextAddLineToPoint(context, round(barCenterX), round(barCenterY));
        
        firstPoint = NO;
        barCenterX += barDisplayWidth;
    }
    
    CGContextStrokePath(context);
    
    barCenterX = oldBarCenterX;
    
    for (NSNumber *value in self.values) {
        CGFloat barSizeHeight = value.doubleValue / 100.0 * displayHeight;
        CGFloat barCenterY = rect.size.height - barSizeHeight - graphBottomPadding;
        CGRect circleRect = CGRectIntegral(CGRectMake(barCenterX - graphCirclesRadius, barCenterY - graphCirclesRadius, graphCirclesRadius * 2.0, graphCirclesRadius * 2.0));
        
        CGContextFillEllipseInRect(context, circleRect);
        CGContextStrokeEllipseInRect(context, circleRect);
        
        barCenterX += barDisplayWidth;
    }
    
    CGContextRestoreGState(context);
}

@end
