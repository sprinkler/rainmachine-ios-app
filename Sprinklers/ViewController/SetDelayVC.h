//
//  SetDelayVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 25/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@interface SetDelayVC : BaseLevel2ViewController

@property (weak, nonatomic) NSString *titlePicker1;
@property (weak, nonatomic) NSString *titlePicker2;
@property (strong, nonatomic) id userInfo;
@property (assign) int valuePicker1;
@property (assign) int valuePicker2;

@property (assign) int minValuePicker1;
@property (assign) int minValuePicker2;

@property (assign) int maxValuePicker1;
@property (assign) int maxValuePicker2;

@property (weak, nonatomic) id<SetDelayVCDelegate> parent;

@end
