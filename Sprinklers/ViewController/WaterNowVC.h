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

@interface WaterNowVC : BaseViewController<SprinklerResponseProtocol>

- (void)toggleWatering:(BOOL)switchValue onZoneWithId:(NSNumber*)theId andCounter:(NSNumber*)counter;

@end
