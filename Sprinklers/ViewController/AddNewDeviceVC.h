//
//  AddNewDeviceVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseNetworkHandlingVC.h"
#import "Protocols.h"

@class Sprinkler;

@interface AddNewDeviceVC :  BaseNetworkHandlingVC <SprinklerResponseProtocol>

@property (strong, nonatomic) Sprinkler *sprinkler;
@property (strong, nonatomic) NSDictionary *cloudResponse;
@property (assign, nonatomic) BOOL cloudUI;
@property (assign, nonatomic) BOOL edit;

@property (strong, nonatomic) NSString *existingEmail;
@property (strong, nonatomic) NSString *existingPassword;

@end
