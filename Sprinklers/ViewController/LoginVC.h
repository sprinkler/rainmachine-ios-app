//
//  LoginVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Sprinkler.h"
#import "SPCommonProtocols.h"

@interface LoginVC : UIViewController <UITextFieldDelegate, SPSprinklerResponseProtocol>

@property (strong, nonatomic) Sprinkler *sprinkler;

@end
