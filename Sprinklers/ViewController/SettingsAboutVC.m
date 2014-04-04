//
//  SettingsAboutVC.m
//  Sprinklers
//
//  Created by Adrian Manolache on 04/04/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "SettingsAboutVC.h"

@interface SettingsAboutVC ()

@end

@implementation SettingsAboutVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"About";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
