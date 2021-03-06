//
//  GraphStyle.m
//  Sprinklers
//
//  Created by Istvan Sipos on 10/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphStyle.h"
#import "GraphDescriptor.h"
#import "GraphVisualAppearanceDescriptor.h"
#import "GraphDisplayAreaDescriptor.h"
#import <CoreText/CoreText.h>

#pragma mark -

@interface GraphStyle ()

- (void)drawText:(NSString*)text
            rect:(CGRect)rect
        textRect:(CGRect)textRect
            font:(UIFont*)font
           color:(UIColor*)color
   textAlignment:(CTTextAlignment)textAlignment
         context:(CGContextRef)context;

@end

#pragma mark -

@implementation GraphStyle

- (id)copyWithZone:(NSZone*)zone {
    GraphStyle *graphStyle = [[[self class] alloc] init];
    graphStyle.graphDescriptor = self.graphDescriptor;
    graphStyle.values = self.values;
    return graphStyle;
}

- (void)plotRasterInRect:(CGRect)rect context:(CGContextRef)context {
    CGContextSaveGState(context);
    
    CGFloat maxValueOriginY = self.graphDescriptor.displayAreaDescriptor.graphBarsTopPadding + self.graphDescriptor.displayAreaDescriptor.valuesDisplayHeight;
    CGFloat minValueOriginY = rect.size.height - self.graphDescriptor.displayAreaDescriptor.graphBarsBottomPadding;
    CGFloat midValueOriginY = round((minValueOriginY + maxValueOriginY) / 2.0);
    
    // Draw dashed lines
    
    CGContextSetStrokeColorWithColor(context, self.graphDescriptor.displayAreaDescriptor.dashedLinesColor.CGColor);
    CGContextSetLineWidth(context, 1.0 / [UIScreen mainScreen].scale);
    CGFloat dashPhase = 0.0;
    CGFloat dashLengths[] = {3.0, 3.0};
    CGContextSetLineDash(context, dashPhase, dashLengths, 2);
    
    CGContextMoveToPoint(context, 0.0, maxValueOriginY);
    CGContextAddLineToPoint(context, rect.size.width, maxValueOriginY);
    
    CGContextMoveToPoint(context, 0.0, midValueOriginY);
    CGContextAddLineToPoint(context, rect.size.width, midValueOriginY);
    
    CGContextMoveToPoint(context, 0.0, minValueOriginY);
    CGContextAddLineToPoint(context, rect.size.width, minValueOriginY);
    
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

- (void)plotGraphInRect:(CGRect)rect context:(CGContextRef)context {
    
}

- (void)plotInRect:(CGRect)rect context:(CGContextRef)context {
    if (self.shouldDrawRaster) [self plotRasterInRect:rect context:context];
    if (self.values != nil) [self plotGraphInRect:rect context:context];
}

#pragma mark - Helper methods

- (void)drawText:(NSString*)text
            rect:(CGRect)rect
        textRect:(CGRect)textRect
            font:(UIFont*)font
           color:(UIColor*)color
   textAlignment:(CTTextAlignment)textAlignment
         context:(CGContextRef)context {
    
    textRect.origin.y = rect.size.height - textRect.origin.y - textRect.size.height;
    
    CGContextSaveGState(context);
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CTFontRef textFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    
    CGMutablePathRef pathToRenderIn = CGPathCreateMutable();
    CGPathAddRect(pathToRenderIn, NULL, textRect);
    
    CTParagraphStyleSetting paragraphStyleSettings[] = {{kCTParagraphStyleSpecifierAlignment, sizeof(textAlignment), &textAlignment}};
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyleSettings, sizeof(paragraphStyleSettings) / sizeof(paragraphStyleSettings[0]));
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
    CFAttributedStringSetAttribute((__bridge CFMutableAttributedStringRef)attributedText, CFRangeMake(0, attributedText.length), kCTFontAttributeName, textFont);
    CFAttributedStringSetAttribute((__bridge CFMutableAttributedStringRef)attributedText, CFRangeMake(0, attributedText.length), kCTForegroundColorAttributeName, color.CGColor);
    CFAttributedStringSetAttribute((__bridge CFMutableAttributedStringRef)attributedText, CFRangeMake(0, attributedText.length), kCTParagraphStyleAttributeName, paragraphStyle);

    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedText);
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, attributedText.length), pathToRenderIn, NULL);
    
    CTFrameDraw(frame, context);
    
    CFRelease(frame);
    CFRelease(pathToRenderIn);
    CFRelease(frameSetter);
    
    CGContextRestoreGState(context);
}

@end
