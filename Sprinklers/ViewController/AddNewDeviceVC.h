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

@interface AddNewDeviceVC :  BaseNetworkHandlingVC <SprinklerResponseProtocol, UIAlertViewDelegate>

@property (weak, nonatomic) UIViewController *parent;

@property (strong, nonatomic) Sprinkler *sprinkler;
@property (assign, nonatomic) BOOL cloudUI;
@property (assign, nonatomic) BOOL edit;

@property (strong, nonatomic) NSString *existingEmail;
@property (strong, nonatomic) NSString *existingPassword;

- (IBAction)onShowPassword:(id)sender;
- (IBAction)onSave:(id)sender;

@end
