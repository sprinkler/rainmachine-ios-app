//
//  SPUtils.h
//  Sprinklers
//
//  Created by Fabian Matyas on 15/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPUtils : NSObject

+ (int)checkOSVersion;
+ (BOOL)retinaScreen;
+ (NSString*)pathForWeatherImageWithName:(NSString*)imageName forHomeScreen:(BOOL)forHomeScreen;
+ (NSNumber*)fixedZoneCounter:(NSNumber*)counter;

@end
