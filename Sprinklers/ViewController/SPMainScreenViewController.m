//
//  SPMainScreenViewController.m
//  Sprinklers
//
//  Created by Fabian Matyas on 04/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SPMainScreenViewController.h"
#import "SPServerProxy.h"
#import "SPConstants.h"

@interface SPMainScreenViewController ()

@end

@implementation SPMainScreenViewController

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
  self.serverProxy = [[SPServerProxy alloc] initWithServerURL:SPTestServerURL delegate:self];
  [self.serverProxy requestWeatherData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error
{
}

- (void)serverResponseReceived:(id)data
{
}

- (void)loginSucceeded
{
}

- (void)loggedOut
{
}

@end
