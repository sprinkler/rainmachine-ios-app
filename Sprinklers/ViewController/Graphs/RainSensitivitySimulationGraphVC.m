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
#import "MixerDailyValue.h"

#pragma mark -

@interface RainSensitivitySimulationGraphVC ()

@property (nonatomic, strong) NSArray *graphMonthCells;

- (void)reloadGraph;
- (void)centerCurrentMonthAnimated:(BOOL)animate;

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
    [self centerCurrentMonthAnimated:NO];
}

#pragma mark - Methods

- (void)reloadGraph {
    CGFloat graphMonthCellWidth = round(self.view.frame.size.width / 3.0);
    CGFloat graphMonthCellHeight = self.graphScrollView.frame.size.height;
    
    NSMutableArray *graphMonthCells = [NSMutableArray new];
    
    NSInteger month = 0;
    for (month = 0; month < 12; month++) {
        RainSensitivityGraphMonthCell *graphMonthCell = [RainSensitivityGraphMonthCell newGraphMonthCell];
        graphMonthCell.monthLabel.text = monthsOfYear[month].uppercaseString;
        
        CGFloat graphMonthCellX = month * graphMonthCellWidth;
        graphMonthCell.frame = CGRectMake(graphMonthCellX, 0.0, graphMonthCellWidth, graphMonthCellHeight);
        
        [self.graphScrollView addSubview:graphMonthCell];
        [graphMonthCells addObject:graphMonthCell];
    }
    
    self.graphScrollView.contentSize = CGSizeMake(12.0 * graphMonthCellWidth, graphMonthCellHeight);
    self.graphMonthCells = graphMonthCells;
}

- (void)centerCurrentMonthAnimated:(BOOL)animate {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitMonth fromDate:[NSDate date]];
    
    if (dateComponents.month >= self.graphMonthCells.count) return;
    
    RainSensitivityGraphMonthCell *graphMonthCellToCenter = self.graphMonthCells[dateComponents.month];
    CGFloat centerX = graphMonthCellToCenter.frame.origin.x + round(graphMonthCellToCenter.frame.size.width / 2.0);
    CGFloat startX = centerX - round(self.graphScrollView.frame.size.width / 2.0);
    if (startX < 0.0) startX = 0.0;
    if (startX + self.graphScrollView.frame.size.width >= self.graphScrollView.contentSize.width) {
        startX = self.graphScrollView.contentSize.width - self.graphScrollView.frame.size.width;
    }
    if (startX < 0.0) startX = 0.0;
    
    [self.graphScrollView setContentOffset:CGPointMake(startX, 0.0) animated:animate];
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
