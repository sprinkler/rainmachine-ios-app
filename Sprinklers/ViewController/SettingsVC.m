//
//  SettingsVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SettingsVC.h"
#import "Additions.h"
#import "DevicesVC.h"
#import "SettingsTestLevel1VC.h"

@interface SettingsVC ()

@end

@implementation SettingsVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //TODO: Load current sprinkler from SettingsManager here and update content if needed.
}

#pragma mark - Actions

- (IBAction)next:(id)sender {
    SettingsTestLevel1VC *level1 = [[SettingsTestLevel1VC alloc] init];
    [self.navigationController pushViewController:level1 animated:YES];
}

@end
