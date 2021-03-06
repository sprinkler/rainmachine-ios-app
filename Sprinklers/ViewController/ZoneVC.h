//
//  ZonePropertiesVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 09/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Zone.h"
#import "Protocols.h"
#import "CCTBackButtonActionHelper.h"

@class VegetationTypeVC;
@class WaterNowVC;
@class ZoneProperties4;

@interface ZoneVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate, SprinklerResponseProtocol, CCTBackButtonActionHelperProtocol, CellButtonDelegate, SetDelayVCDelegate>

@property (nonatomic, copy) Zone *zone;
@property (nonatomic) BOOL showMasterValve;
@property (nonatomic, weak) WaterNowVC *parent;
@property (assign) int zoneIndex;

@property (copy, nonatomic) Zone *zoneCopyBeforeSave;
@property (assign) BOOL showInitialUnsavedAlert;
@property (assign) ZoneProperties4 *zoneProperties;
@property (assign) ZoneProperties4 *unsavedZoneProperties;

- (void)vegetationTypeVCWillDissapear:(VegetationTypeVC*)vegetationTypeVC;

@end
