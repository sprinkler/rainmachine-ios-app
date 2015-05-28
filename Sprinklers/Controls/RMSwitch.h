//
//  RMSwitch.h
//  Sprinklers
//
//  Created by Fabian Matyas on 18/06/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WaterZoneListCell;

@interface RMSwitch : UISwitch

@property (nonatomic, assign) BOOL isUnderUserTracking;
@property (nonatomic, weak) WaterZoneListCell *cell;

@end
