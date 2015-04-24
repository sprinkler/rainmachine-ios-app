//
//  WateringHistoryVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 24/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "WateringHistoryVC.h"
#import "WateringHistoryCell.h"
#import "WateringHistorySection.h"
#import "ServerProxy.h"
#import "WaterLogDay.h"
#import "WaterLogProgram.h"
#import "WaterLogZone.h"
#import "Program.h"
#import "Zone.h"
#import "Additions.h"
#import "Constants.h"
#import "Utils.h"
#import "MBProgressHUD.h"

const NSInteger WateringHistoryNumberOfDays     = 7;

#pragma mark -

@interface WateringHistoryVC ()

@property (nonatomic, strong) ServerProxy *requestWaterLogServerProxy;
@property (nonatomic, strong) ServerProxy *requestProgramsServerProxy;
@property (nonatomic, strong) ServerProxy *requestZonesServerProxy;
@property (nonatomic, strong) NSArray *waterLog;
@property (nonatomic, strong) NSDictionary *waterLogDictionary;
@property (nonatomic, strong) NSArray *programs;
@property (nonatomic, strong) NSArray *zones;
@property (nonatomic, strong) NSArray *dates;
@property (nonatomic, strong) NSArray *dateStrings;
@property (nonatomic, strong) NSArray *shortDateStrings;

- (void)requestWaterLog;
- (void)requestPrograms;
- (void)requestZones;

- (void)initializeDates;
- (NSString*)dateStringFromDate:(NSDate*)date;
- (NSString*)shortDateStringFromDate:(NSDate*)date;
- (NSDictionary*)waterLogDictionaryFromWaterLogData:(NSArray*)waterLogData;

@property (nonatomic, readonly) NSDate *startDate;
@property (nonatomic, assign) BOOL finishedLoading;

- (UITableViewCell*)dequeueSimpleCell;
- (UITableViewCell*)dequeueWateringHistoryCell;

- (void)updateTitleCell:(UITableViewCell*)cell;
- (void)updateDayTitleCell:(UITableViewCell*)cell shortDateString:(NSString*)shortDateString;
- (void)updateNoWateringDataCell:(UITableViewCell*)cell;
- (void)updateWateringHistoryCell:(UITableViewCell*)cell
                  waterLogProgram:(WaterLogProgram*)waterLogProgram
                     waterLogZone:(WaterLogZone*)waterLogZone;

@property (nonatomic, strong) NSArray *wateringHistorySections;

- (void)createWateringHistorySections;

@end

#pragma mark -

@implementation WateringHistoryVC {
    MBProgressHUD *hud;
}

#pragma mark - Init

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Watering History";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"WateringHistoryCell" bundle:nil] forCellReuseIdentifier:@"WateringHistoryCell"];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Export"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(onExport:)];
    [self initializeDates];
    [self requestWaterLog];
    [self requestPrograms];
    [self requestZones];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Requets

- (void)requestWaterLog {
    self.requestWaterLogServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.requestWaterLogServerProxy requestWateringLogDetailsFromDate:[self dateStringFromDate:self.startDate]
                                                             daysCount:WateringHistoryNumberOfDays];
    [self startHud:nil];
}

- (void)requestPrograms {
    self.requestProgramsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.requestProgramsServerProxy requestPrograms];
    [self startHud:nil];
}

- (void)requestZones {
    self.requestZonesServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.requestZonesServerProxy requestZones];
    [self startHud:nil];
}

- (void)startHud:(NSString *)text {
    if (hud) return;
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
}

#pragma mark - Methods

- (NSString*)dateStringFromDate:(NSDate*)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    return [NSString stringWithFormat:@"%d-%02d-%02d", (int)dateComponents.year,(int)dateComponents.month,(int)dateComponents.day];
}

- (NSDate*)startDate {
    return [[NSDate date] dateBySubtractingDays:WateringHistoryNumberOfDays - 1];
}

- (NSString*)shortDateStringFromDate:(NSDate*)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    return [NSString stringWithFormat:@"%@ %d",abbrevMonthsOfYear[dateComponents.month - 1],(int)dateComponents.day];
}

- (void)initializeDates {
    NSMutableArray *dates = [NSMutableArray new];
    NSMutableArray *dateStrings = [NSMutableArray new];
    NSMutableArray *shortDateStrings = [NSMutableArray new];
    
    for (NSInteger day = 0; day < WateringHistoryNumberOfDays; day++) {
        NSDate *date = [self.startDate dateByAddingDays:day];
        NSString *dateString = [self dateStringFromDate:date];
        NSString *shortDateString = (date.isToday ? @"Today" : [self shortDateStringFromDate:date]);
        [dates addObject:date];
        [dateStrings addObject:dateString];
        [shortDateStrings addObject:shortDateString];
    }
    
    self.dates = dates;
    self.dateStrings = dateStrings;
    self.shortDateStrings = shortDateStrings;
}

- (NSDictionary*)waterLogDictionaryFromWaterLogData:(NSArray*)waterLogData {
    NSMutableDictionary *waterLogDictionary = [NSMutableDictionary new];
    
    for (WaterLogDay *waterLogDay in waterLogData) {
        if (!waterLogDay.date.length) continue;
        [waterLogDictionary setObject:waterLogDay forKey:waterLogDay.date];
    }
    
    return waterLogDictionary;
}

#pragma mark - Cells

- (UITableViewCell*)dequeueSimpleCell {
    static NSString *WateringLogSimpleCellIdentifier = @"WateringLogSimpleCell";

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:WateringLogSimpleCellIdentifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:WateringLogSimpleCellIdentifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (UITableViewCell*)dequeueWateringHistoryCell {
    static NSString *WateringLogDayCellIdentifier = @"WateringHistoryCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:WateringLogDayCellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)updateTitleCell:(UITableViewCell*)cell {
    cell.textLabel.text = @"7 Day Watering History";
    cell.textLabel.font = [UIFont boldSystemFontOfSize:19.0];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = [UIColor blackColor];
}

- (void)updateDayTitleCell:(UITableViewCell*)cell shortDateString:(NSString*)shortDateString {
    if ([cell isKindOfClass:[WateringHistoryCell class]]) {
        WateringHistoryCell *wateringHistoryCell = (WateringHistoryCell*)cell;
        
        wateringHistoryCell.titleLabel.text = shortDateString;
        wateringHistoryCell.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
        wateringHistoryCell.titleLabel.textAlignment = NSTextAlignmentLeft;
        wateringHistoryCell.titleLabel.textColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
        
        wateringHistoryCell.firstColumnLabel.text = @"Scheduled";
        wateringHistoryCell.firstColumnLabel.font = [UIFont boldSystemFontOfSize:15.0];
        wateringHistoryCell.firstColumnLabel.textAlignment = NSTextAlignmentCenter;
        wateringHistoryCell.firstColumnLabel.textColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
        
        wateringHistoryCell.secondColumnLabel.text = @"Watered";
        wateringHistoryCell.secondColumnLabel.font = [UIFont boldSystemFontOfSize:15.0];
        wateringHistoryCell.secondColumnLabel.textAlignment = NSTextAlignmentCenter;
        wateringHistoryCell.secondColumnLabel.textColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
    } else {
        cell.textLabel.text = shortDateString;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
    }
    
    cell.backgroundColor = [UIColor whiteColor];
}

- (void)updateNoWateringDataCell:(UITableViewCell*)cell {
    cell.textLabel.text = @"No watering data";
    cell.textLabel.font = [UIFont systemFontOfSize:15.0];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.backgroundColor = [UIColor whiteColor];
}

- (void)updateWateringHistoryCell:(UITableViewCell*)cell
                  waterLogProgram:(WaterLogProgram*)waterLogProgram
                     waterLogZone:(WaterLogZone*)waterLogZone {
    
    if ([cell isKindOfClass:[WateringHistoryCell class]]) {
        NSString *zoneName = nil;
        for (Zone *zone in self.zones) {
            if (zone.zoneId == waterLogZone.zoneId) {
                zoneName = zone.name;
                break;
            }
        }
        WateringHistoryCell *wateringHistoryCell = (WateringHistoryCell*)cell;

        wateringHistoryCell.titleLabel.text = zoneName;
        wateringHistoryCell.titleLabel.font = [UIFont systemFontOfSize:15.0];
        wateringHistoryCell.titleLabel.textAlignment = NSTextAlignmentLeft;
        wateringHistoryCell.titleLabel.textColor = [UIColor blackColor];
        
        wateringHistoryCell.firstColumnLabel.text = [Utils formattedTimeFromSeconds:waterLogZone.userDurationSum];
        wateringHistoryCell.firstColumnLabel.font = [UIFont systemFontOfSize:15.0];
        wateringHistoryCell.firstColumnLabel.textAlignment = NSTextAlignmentCenter;
        wateringHistoryCell.firstColumnLabel.textColor = [UIColor blackColor];
        
        wateringHistoryCell.secondColumnLabel.text = [Utils formattedTimeFromSeconds:waterLogZone.realDurationSum];
        wateringHistoryCell.secondColumnLabel.font = [UIFont systemFontOfSize:15.0];
        wateringHistoryCell.secondColumnLabel.textAlignment = NSTextAlignmentCenter;
        wateringHistoryCell.secondColumnLabel.textColor = [UIColor blackColor];
    } else {
        NSString *programName = nil;
        if (waterLogProgram.programId == 0) programName = @"Manual watering";
        else {
            for (Program *program in self.programs) {
                if (program.programId == waterLogProgram.programId) {
                    programName = program.name;
                    break;
                }
            }
        }
        cell.textLabel.text = programName;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    cell.backgroundColor = [UIColor whiteColor];
}

- (void)createWateringHistorySections {
    NSMutableArray *wateringHistorySections = [NSMutableArray new];
    
    [wateringHistorySections addObject:[WateringHistorySection sectionWithType:WateringHistorySectionTypeHeader
                                                                   waterLogDay:nil
                                                               waterLogProgram:nil]];
    
    for (NSString *dateString in self.dateStrings.reverseObjectEnumerator.allObjects) {
        WaterLogDay *waterLogDay = [self.waterLogDictionary objectForKey:dateString];
        if (!waterLogDay) {
            waterLogDay = [WaterLogDay new];
            waterLogDay.date = dateString;
        }
        
        [wateringHistorySections addObject:[WateringHistorySection sectionWithType:WateringHistorySectionTypeWaterLogDayHeader
                                                                       waterLogDay:waterLogDay
                                                                   waterLogProgram:nil]];
        if (waterLogDay.programs.count) {
            for (WaterLogProgram *waterLogProgram in waterLogDay.programs) {
                [wateringHistorySections addObject:[WateringHistorySection sectionWithType:WateringHistorySectionTypeWaterLogProgram
                                                                               waterLogDay:waterLogDay
                                                                           waterLogProgram:waterLogProgram]];
            }
        } else {
            [wateringHistorySections addObject:[WateringHistorySection sectionWithType:WateringHistorySectionTypeWaterLogProgram
                                                                           waterLogDay:waterLogDay
                                                                       waterLogProgram:nil]];
        }
    }
    
    self.wateringHistorySections = wateringHistorySections;
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.requestWaterLogServerProxy) {
        self.waterLog = data;
        self.waterLogDictionary = [self waterLogDictionaryFromWaterLogData:data];
        self.requestWaterLogServerProxy = nil;
    }
    else if (serverProxy == self.requestProgramsServerProxy) {
        self.programs = data;
        self.requestProgramsServerProxy = nil;
    }
    else if (serverProxy == self.requestZonesServerProxy) {
        self.zones = data;
        self.requestZonesServerProxy = nil;
    }
    
    if (!self.requestWaterLogServerProxy && !self.requestProgramsServerProxy && !self.requestZonesServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        hud = nil;
        [self createWateringHistorySections];
        self.finishedLoading = YES;
    }
    
    [self.tableView reloadData];
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    if (serverProxy == self.requestWaterLogServerProxy) self.requestWaterLogServerProxy = nil;
    else if (serverProxy == self.requestProgramsServerProxy) self.requestProgramsServerProxy = nil;
    else if (serverProxy == self.requestZonesServerProxy) self.requestZonesServerProxy = nil;
    
    if (!self.requestWaterLogServerProxy && !self.requestProgramsServerProxy && !self.requestZonesServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        hud = nil;
    }
    
    [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    [self.tableView reloadData];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - UITableView datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self.finishedLoading ? self.wateringHistorySections.count : 0);
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    WateringHistorySection *wateringHistorySection = self.wateringHistorySections[section];
    return wateringHistorySection.numberOfRows;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    WateringHistorySection *wateringHistorySection = self.wateringHistorySections[section];
    if (wateringHistorySection.sectionType == WateringHistorySectionTypeWaterLogDayHeader) return 36.0;
    if (wateringHistorySection.sectionType == WateringHistorySectionTypeWaterLogProgram) return 2.0;
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    WateringHistorySection *wateringHistorySection = self.wateringHistorySections[section];
    if (wateringHistorySection == self.wateringHistorySections.lastObject) return UITableViewAutomaticDimension;
    return 2.0;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 44.0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = nil;
    
    WateringHistorySection *wateringHistorySection = self.wateringHistorySections[indexPath.section];
    
    if (wateringHistorySection.sectionType == WateringHistorySectionTypeHeader) {
        UITableViewCell *cell = [self dequeueSimpleCell];
        [self updateTitleCell:cell];
        return cell;
    }

    if (wateringHistorySection.sectionType == WateringHistorySectionTypeWaterLogDayHeader) {
        UITableViewCell *cell = (wateringHistorySection.waterLogDay.programs.count ? [self dequeueWateringHistoryCell] : [self dequeueSimpleCell]);
        NSInteger dateStringIndex = [self.dateStrings indexOfObject:wateringHistorySection.waterLogDay.date];
        NSString *shortDateString = (dateStringIndex != NSNotFound ? [self.shortDateStrings objectAtIndex:dateStringIndex] : nil);
        [self updateDayTitleCell:cell shortDateString:shortDateString];
        return cell;
    }
    
    if (wateringHistorySection.sectionType == WateringHistorySectionTypeWaterLogProgram) {
        WaterLogProgram *waterLogProgram = wateringHistorySection.waterLogProgram;

        if (waterLogProgram) {
            WaterLogZone *waterLogZone = (indexPath.row > 0 ? waterLogProgram.zones[indexPath.row - 1] : nil);
            UITableViewCell *cell = (waterLogZone ? [self dequeueWateringHistoryCell] : [self dequeueSimpleCell]);
            [self updateWateringHistoryCell:cell waterLogProgram:wateringHistorySection.waterLogProgram waterLogZone:waterLogZone];
            return cell;
        }
        
        cell = [self dequeueSimpleCell];
        [self updateNoWateringDataCell:cell];
        
        return cell;
    }
    
    return nil;
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (IBAction)onExport:(id)sender {
    
}

@end
