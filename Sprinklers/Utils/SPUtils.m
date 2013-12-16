//
//  SPUtils.m
//  Sprinklers
//
//  Created by Fabian Matyas on 15/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SPUtils.h"

@implementation SPUtils

#pragma mark - Sprinkler specific utils

+ (NSString*)pathForWeatherImageWithName:(NSString*)imageName forHomeScreen:(BOOL)forHomeScreen
{
  NSString *dataFolder = [[NSBundle mainBundle] resourcePath];
  if (forHomeScreen) {
    dataFolder = [dataFolder stringByAppendingPathComponent:@"main-screen-normal-and-retina-sizes"];
  } else {
    dataFolder = [dataFolder stringByAppendingPathComponent:@"daily-stats"];
  }
  
  NSString *imagePath = [dataFolder stringByAppendingPathComponent:imageName];
  
  if ([SPUtils retinaScreen]) {
    imagePath = [imagePath stringByAppendingString:@"@2x"];
  }
  
  imagePath = [imagePath stringByAppendingPathExtension:@"png"];
  
  return imagePath;
}

+ (NSNumber*)fixedZoneCounter:(NSNumber*)counter
{
  if ([counter intValue] == 0) {
    return [NSNumber numberWithInteger:5 * 60]; // 5 minutes
  }
  
  return counter;
}

#pragma mark - 

static BOOL isRetinaScreen = NO;
static BOOL didRetinaCheck = NO;
+ (BOOL)retinaScreen
{
  if (!didRetinaCheck) {
    isRetinaScreen = ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
                      ([UIScreen mainScreen].scale == 2.0));
    didRetinaCheck = YES;
  }
  return isRetinaScreen;
}

+ (int)checkOSVersion {
  
  NSArray *ver = [[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."];
  int osVerson = [[ver objectAtIndex:0] intValue];
  return osVerson;
}

@end
