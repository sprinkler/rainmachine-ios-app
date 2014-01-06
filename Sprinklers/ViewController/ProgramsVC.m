//
//  ProgramsVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 05/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProgramsVC.h"
#import "Constants.h"
#import "ServerProxy.h"
#import "Program.h"
#import "MBProgressHUD.h"

@interface ProgramsVC ()

@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) ServerProxy *postServerProxy;

@end

@implementation ProgramsVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Programs";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.serverProxy = [[ServerProxy alloc] initWithServerURL:TestServerURL delegate:self jsonRequest:NO];
    self.postServerProxy = [[ServerProxy alloc] initWithServerURL:TestServerURL delegate:self jsonRequest:YES];
    
    [self.serverProxy requestPrograms];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy {
    if (data && [data isKindOfClass:[NSArray class]]) {
        for (Program *p in data) {
            
        }
    }
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

@end
