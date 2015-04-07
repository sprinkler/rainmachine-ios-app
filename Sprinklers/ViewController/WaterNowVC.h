//
//  WaterNowVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "Protocols.h"

@class MBProgressHUD;
@class ServerProxy;
@class WaterNowZone;
@class Zone;

@interface WaterNowVC : BaseViewController<SprinklerResponseProtocol, CounterHelperDelegate, RainDelayPollerDelegate>

@property (assign, nonatomic) BOOL delayedInitialListRefresh;

- (void)toggleWateringOnZone:(WaterNowZone*)zone withCounter:(NSNumber*)counter;
- (void)setWateringOnZone:(WaterNowZone*)zone toState:(int)state withCounter:(NSNumber*)counter;
- (void)addZoneToStateChangeObserver:(WaterNowZone*)zone;
- (void)removeZoneFromStateChangeObserver:(WaterNowZone*)zone;
- (void)userStartedZone:(WaterNowZone*)zone;
- (void)userStoppedZone:(WaterNowZone*)zone;

- (void)setZone:(Zone*)zone withIndex:(int)i;
- (void)setUnsavedZone:(Zone*)zone withIndex:(int)i;

@end
