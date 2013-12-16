//
//  SPFormatterHelper.m
//  Sprinklers
//
//  Created by Fabian Matyas on 14/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SPFormatterHelper.h"

@implementation SPFormatterHelper

+ (NSString*)formattedTime:(int)timeInSeconds
{
  NSString *formattedTime;
  if (timeInSeconds < 3600) {
    formattedTime = [NSString stringWithFormat:@"%02d:%02d", (timeInSeconds/60)%60, timeInSeconds%60];
  } else {
    formattedTime = [NSString stringWithFormat:@"%02d:%02d:%02d", timeInSeconds / 3600, (timeInSeconds/60)%60, timeInSeconds%60];
  }
  
  return formattedTime;
}

@end
