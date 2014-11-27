//
//  RainSensitivitySimulationGraphVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RainSensitivitySimulationGraphVC.h"
#import "RainSensitivityVC.h"
#import "SettingsVC.h"
#import "RainSensitivityGraphMonthCell.h"
#import "Constants.h"

#pragma mark -

@interface RainSensitivitySimulationGraphVC ()

- (void)reloadGraph;

@end

#pragma mark -

@implementation RainSensitivitySimulationGraphVC

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadGraph];
}

#pragma mark - Methods

- (void)reloadGraph {
    CGFloat graphMonthCellWidth = round(self.view.frame.size.width / 3.0);
    CGFloat graphMonthCellHeight = self.graphScrollView.frame.size.height;
    
    NSInteger month = 0;
    for (month = 0; month < 12; month++) {
        RainSensitivityGraphMonthCell *graphMonthCell = [RainSensitivityGraphMonthCell newGraphMonthCell];
        graphMonthCell.monthLabel.text = monthsOfYear[month].uppercaseString;
        
        CGFloat graphMonthCellX = month * graphMonthCellWidth;
        graphMonthCell.frame = CGRectMake(graphMonthCellX, 0.0, graphMonthCellWidth, graphMonthCellHeight);
        
        [self.graphScrollView addSubview:graphMonthCell];
    }
    
    self.graphScrollView.contentSize = CGSizeMake(12.0 * graphMonthCellWidth, graphMonthCellHeight);
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
}

- (void)loggedOut {
    [self.parent handleLoggedOutSprinklerError];
}

@end
