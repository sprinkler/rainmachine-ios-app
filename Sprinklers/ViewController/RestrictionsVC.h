//
//  RestrictionsVC.h
//  Sprinklers
//
//  Created by Adrian Manolache on 07/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServerProxy.h"
#import "MBProgressHUD.h"
    
@interface RestrictionsVC : UIViewController<SprinklerResponseProtocol>
{
}

@property(nonatomic, retain) ServerProxy* serverProxy;
    
@property(nonatomic, retain) UIAlertView* alertView;

@property(nonatomic, retain) MBProgressHUD* hud;

@end
