//
//  SettingsAbout4VC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 26/02/15.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class SettingsVC;

@interface SettingsAbout4VC : BaseLevel2ViewController <SprinklerResponseProtocol, UpdateManagerDelegate> {

}

@property (nonatomic, strong) SettingsVC *parent;

@end
