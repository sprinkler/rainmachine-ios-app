//
//  ZoneAdvancedVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 30/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"
#import "Protocols.h"
#import "CCTBackButtonActionHelper.h"

@class Zone;
@class ZoneVC;
@class ZoneProperties4;

@interface ZoneAdvancedVC : BaseLevel2ViewController <CCTBackButtonActionHelperProtocol, SprinklerResponseProtocol, UIAlertViewDelegate>

@property (nonatomic, strong) Zone *zone;
@property (nonatomic, weak) ZoneVC *parent;
@property (nonatomic, strong) ZoneProperties4 *zoneProperties;
@property (nonatomic, strong) ZoneProperties4 *unsavedZoneProperties;

- (void)advancedPropertiesTableViewDidEdit;

@property (nonatomic, assign) BOOL showInitialUnsavedAlert;

@end
