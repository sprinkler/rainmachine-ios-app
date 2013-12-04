//
//  SPLoginViewController.h
//  Sprinklers
//
//  Created by Fabian Matyas on 03/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCommonProtocols.h"

@class Sprinkler;
@class SPServerProxy;
@class MBProgressHUD;

@interface SPLoginViewController : UITableViewController<SPSprinklerResponseProtocol>
//@property (weak, nonatomic) IBOutlet UIView *theTitleView;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceIPLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkBox;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (strong, nonatomic) Sprinkler *sprinkler;
@property (strong, nonatomic) SPServerProxy *serverProxy;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) UIView *loadingOverlay;
@property (strong, nonatomic) UIAlertView *alertView;

- (IBAction)onLogin:(id)sender;

@end
