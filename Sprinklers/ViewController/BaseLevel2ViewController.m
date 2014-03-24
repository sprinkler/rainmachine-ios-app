//
//  BaseLevel2ViewController.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"
#import "Additions.h"
#import "StorageManager.h"
#import "BaseViewController.h"

@interface BaseLevel2ViewController ()

@end

@implementation BaseLevel2ViewController

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:kSprinklerWaterColor[0] green:kSprinklerWaterColor[1] blue:kSprinklerWaterColor[2] alpha:1];
        self.navigationController.navigationBar.translucent = NO;
    }
}

@end
