//
//  MonthsVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 27/09/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@interface MonthsVC : BaseLevel2ViewController

@property (nonatomic, strong) NSMutableArray *selectedMonths;

@property (weak, nonatomic) BaseNetworkHandlingVC<MonthsVCDelegate> *parent;

@end
