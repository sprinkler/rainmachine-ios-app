//
//  AvailableWiFisVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 03/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"
#import "BaseLevel2ViewController.h"
#import "Sprinkler.h"

@interface AvailableWiFisVC : BaseLevel2ViewController<SprinklerResponseProtocol>

@property (strong, nonatomic) NSString *macAddressOfSprinklerWithWiFiSetup;
@property (strong, nonatomic) Sprinkler *inputSprinkler;

- (void)joinWiFi:(NSString*)SSID encryption:(NSString*)encryption key:(NSString*)password sprinklerId:(NSString*)sprinklerId;

@end
