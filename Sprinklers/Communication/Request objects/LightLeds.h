//
//  LightLeds.h
//  Sprinklers
//
//  Created by Istvan Sipos on 04/05/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocols.h"

@interface LightLeds : NSObject <SprinklerResponseProtocol>

@property (nonatomic, strong) NSString *sprinklerURL;

+ (LightLeds*)sharedLightLeds;
- (void)enableLightLeds;
- (void)disableLightLeds;

@end
