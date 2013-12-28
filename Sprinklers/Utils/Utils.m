//
//  SPUtils.m
//  Sprinklers
//
//  Created by Fabian Matyas on 15/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "Utils.h"
#import "+UIImage.h"
#import "Constants.h"

@implementation Utils

#pragma mark - General Sprinkler utils

+ (NSNumber*)fixedZoneCounter:(NSNumber*)counter
{
  if ([counter intValue] == 0) {
    return [NSNumber numberWithInteger:5 * 60]; // 5 minutes
  }
  
  return counter;
}

#pragma mark - Sprinkler water image generation

+ (UIImage*)waterWavesImage:(float)height
{
  float kLineWidth = 1 * [[UIScreen mainScreen] scale];
  float kWaveAmplitude = 1 * [[UIScreen mainScreen] scale];
  CAShapeLayer *layer = [CAShapeLayer layer];
  layer.strokeColor = [UIColor colorWithRed:kWaterImageStrokeColor[0] green:kWaterImageStrokeColor[1] blue:kWaterImageStrokeColor[2] alpha:1].CGColor;
  layer.fillColor = [UIColor colorWithRed:kWaterImageFillColor[0] green:kWaterImageFillColor[1] blue:kWaterImageFillColor[2] alpha:1].CGColor;
  layer.lineWidth = kLineWidth;
  layer.lineCap = kCALineCapRound;
  layer.lineJoin = kCALineJoinRound;
  
  layer.frame = CGRectMake(0, 0, 2 * kWaveAmplitude + 2 * kLineWidth, height * [[UIScreen mainScreen] scale]);
  
  float x = layer.frame.size.width / 2;
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathMoveToPoint(path, NULL, -kLineWidth, kLineWidth);
  CGPathAddLineToPoint(path, NULL, x, kLineWidth);
  
  float verticalWavesNumber = 9;
  float maxY = layer.frame.size.height - kLineWidth;
  for (int y = kLineWidth; y <= maxY; y++) {
    float angle = -M_PI + (M_PI * verticalWavesNumber * (y - kLineWidth)) / (maxY - kLineWidth);
    float dx = kWaveAmplitude * sinf(angle);
    CGPathAddLineToPoint(path, NULL, x + dx, y);
  }
  CGPathAddLineToPoint(path, NULL, -kLineWidth, maxY);
  
  CGPathCloseSubpath(path);
  
  layer.path = path;
  
  CGPathRelease(path);
  
  return [UIImage imageFromLayer:layer];
}

+ (UIImage*)waterImage:(float)height
{
  float kLineWidth = 1 * [[UIScreen mainScreen] scale];
  CAShapeLayer *layer = [CAShapeLayer layer];
  layer.strokeColor = [UIColor colorWithRed:kWaterImageStrokeColor[0] green:kWaterImageStrokeColor[1] blue:kWaterImageStrokeColor[2] alpha:1].CGColor;
  layer.fillColor = [UIColor colorWithRed:kWaterImageFillColor[0] green:kWaterImageFillColor[1] blue:kWaterImageFillColor[2] alpha:1].CGColor;
  layer.lineWidth = kLineWidth;
  layer.lineCap = kCALineCapRound;
  layer.lineJoin = kCALineJoinRound;
  
  layer.frame = CGRectMake(0, 0, 1, height * [[UIScreen mainScreen] scale]);
  
  float maxY = layer.frame.size.height - kLineWidth;
  
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathMoveToPoint(path, NULL, -2 * kLineWidth, kLineWidth);
  CGPathAddLineToPoint(path, NULL, 2 * kLineWidth, kLineWidth);
  CGPathAddLineToPoint(path, NULL, 2 * kLineWidth, maxY);
  CGPathAddLineToPoint(path, NULL, -2 * kLineWidth, maxY);
  
  CGPathCloseSubpath(path);
  
  layer.path = path;
  
  CGPathRelease(path);
  
  return [UIImage imageFromLayer:layer];
}

#pragma mark - General

+ (int)checkOSVersion {
    
    NSArray *ver = [[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."];
    int osVerson = [[ver objectAtIndex:0] intValue];
    return osVerson;
}

@end
