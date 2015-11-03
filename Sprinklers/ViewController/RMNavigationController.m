//
//  RMNavigationController.m
//  Sprinklers
//
//  Created by Fabian Matyas on 27/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RMNavigationController.h"
#import "CCTBackButtonActionHelper.h"

@interface RMNavigationController ()

@end

@implementation RMNavigationController

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    BOOL should = [[CCTBackButtonActionHelper sharedInstance] navigationController:self
                                                                     navigationBar:navigationBar
                                                                     shouldPopItem:item];
    if (!should) {
        return NO;
    }
    
    return [super navigationBar:navigationBar shouldPopItem:item];
}

@end
