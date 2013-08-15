//
//  UIBezierPath.m
//  FootballSupporter
//
//  Created by Daniel Cristolovean on 12/2/12.
//  Copyright (c) 2012 Foca. All rights reserved.
//

#import "+UIBezierPath.h"

#define kArrowPointCount 7

@implementation UIBezierPath (Additions)

+ (UIBezierPath *)dqd_bezierPathWithArrowFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint tailWidth:(CGFloat)tailWidth headWidth:(CGFloat)headWidth headLength:(CGFloat)headLength {
    CGFloat length = hypotf(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
    CGPoint points[kArrowPointCount];
    [self dqd_getAxisAlignedArrowPoints:points forLength:length tailWidth:tailWidth headWidth:headWidth headLength:headLength];
    
    CGAffineTransform transform = [self dqd_transformForStartPoint:startPoint endPoint:endPoint length:length];
    
    CGMutablePathRef cgPath = CGPathCreateMutable();
    CGPathAddLines(cgPath, &transform, points, sizeof points / sizeof *points);
    CGPathCloseSubpath(cgPath);
    
    UIBezierPath *uiPath = [UIBezierPath bezierPathWithCGPath:cgPath];
    CGPathRelease(cgPath);
    return uiPath;
}

+ (void)dqd_getAxisAlignedArrowPoints:(CGPoint[kArrowPointCount])points forLength:(CGFloat)length tailWidth:(CGFloat)tailWidth headWidth:(CGFloat)headWidth headLength:(CGFloat)headLength {
    CGFloat tailLength = length - headLength;
    points[0] = CGPointMake(0, tailWidth / 2);
    points[1] = CGPointMake(tailLength, tailWidth / 2);
    points[2] = CGPointMake(tailLength, headWidth / 2);
    points[3] = CGPointMake(length, 0);
    points[4] = CGPointMake(tailLength, -headWidth / 2);
    points[5] = CGPointMake(tailLength, -tailWidth / 2);
    points[6] = CGPointMake(0, -tailWidth / 2);
}

+ (CGAffineTransform)dqd_transformForStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint length:(CGFloat)length {
    CGFloat cosine = (endPoint.x - startPoint.x) / length;
    CGFloat sine = (endPoint.y - startPoint.y) / length;
    return (CGAffineTransform){ cosine, sine, -sine, cosine, startPoint.x, startPoint.y };
}

@end
