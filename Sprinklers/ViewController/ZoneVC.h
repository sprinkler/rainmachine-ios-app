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
@class ZonesVC;

@interface ZoneVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate, SprinklerResponseProtocol, CCTBackButtonActionHelperProtocol, CellButtonDelegate, SetDelayVCDelegate>

@property (nonatomic, copy) Zone *zone;
@property (nonatomic) BOOL showMasterValve;
@property (nonatomic, weak) ZonesVC *parent;
@property (assign) int zoneIndex;

@property (copy, nonatomic) Zone *zoneCopyBeforeSave;
@property (assign) BOOL showInitialUnsavedAlert;

- (void)vegetationTypeVCWillDissapear:(VegetationTypeVC*)vegetationTypeVC;

@end
