//
//  AddNewDeviceVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Sprinkler;

@interface AddNewDeviceVC : UIViewController

@property (strong, nonatomic) Sprinkler *sprinkler;
@property (assign, nonatomic) BOOL cloudUI;

@end
