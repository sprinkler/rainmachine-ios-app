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

@interface WaterNowVC : BaseViewController<SprinklerResponseProtocol, WaterNowCounterHelperDelegate>

@property (assign, nonatomic) BOOL delayedInitialListRefresh;

- (void)toggleWateringOnZone:(WaterNowZone*)zone withCounter:(NSNumber*)counter;
- (void)addZoneToStateChangeObserver:(WaterNowZone*)zone;
- (void)removeZoneFromStateChangeObserver:(WaterNowZone*)zone;
- (void)userStartedZone:(WaterNowZone*)zone;
- (void)userStoppedZone:(WaterNowZone*)zone;

@end
