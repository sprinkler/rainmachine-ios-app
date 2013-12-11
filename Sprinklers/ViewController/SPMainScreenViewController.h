//
//  SPMainScreenViewController.h
//  Sprinklers
//
//  Created by Fabian Matyas on 04/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Sprinkler;

@interface SPMainScreenViewController : UITabBarController<UITabBarControllerDelegate>

@property (strong, nonatomic) Sprinkler *sprinkler;

- (void)handleServerLoggedOutUser;

@end
