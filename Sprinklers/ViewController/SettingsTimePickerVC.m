//
//  SettingsTimePickerVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 03/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "SettingsTimePickerVC.h"
#import "SettingsDate.h"
#import "MBProgressHUD.h"
#import "ServerProxy.h"
#import "ServerResponse.h"
#import "SettingsVC.h"
#import "Utils.h"
#import "+UIDevice.h"

@interface SettingsTimePickerVC ()
{
    NSInteger day;
    NSInteger month;
    NSInteger year;
}

@property(weak, nonatomic) IBOutlet UILabel* separatorLabel;

@property (strong, nonatomic) SettingsDate *settingsDate;
@property (strong, nonatomic) ServerProxy *pullServerProxy;
@property (strong, nonatomic) ServerProxy *postServerProxy;

@end

@implementation SettingsTimePickerVC

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
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.pullServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    [self.pullServerProxy requestSettingsDate];

    [self refreshUI];
    
    self.separatorLabel.hidden = YES;
    self.title = @"Time";
}

- (NSDateFormatter*)dateFormatter
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    
    // Date formatting standard. If you follow the links to the "Data Formatting Guide", you will see this information for iOS 6: http://www.unicode.org/reports/tr35/tr35-25.html#Date_Format_Patterns
    if ([self.settingsDate.time_format intValue] == 24) {
        df.dateFormat = @"yyyy/MM/dd H:mm"; // H means hours between [0-23]
    }
    else if ([self.settingsDate.time_format intValue] == 12) {
        df.dateFormat = @"yyyy/MM/dd K:mm a"; // K means hours between [0-11]
    }
    
    return df;
}

- (NSDate*)dateFromString:(NSString*)stringDate
{
    return [[self dateFormatter] dateFromString:stringDate];
}

- (NSString*)stringFromDate:(NSDate*)date
{
    return [[self dateFormatter] stringFromDate:date];
}

- (NSDate*)constructDateFromPicker
{
    NSDate *date = ([self.settingsDate.appDate length] > 0) ? [self dateFromString:self.settingsDate.appDate] : [NSDate date];
    NSCalendar* dateCal = [NSCalendar currentCalendar];
    NSDateComponents* dateComp = [dateCal components:(
                                                      NSYearCalendarUnit |
                                                      NSMonthCalendarUnit |
                                                      NSDayCalendarUnit
                                                      )
                                            fromDate:date];
    

    dateComp.hour = [self hour24Format];
    dateComp.minute = [self minutes];
    
    return [dateCal dateFromComponents:dateComp];
}

- (void)save
{
    if ((self.settingsDate) && (!self.postServerProxy) && (!self.pullServerProxy)) {
        
        NSString *newDate = [self stringFromDate:[self constructDateFromPicker]];
        
        // If we save the same unit again the server returns error: "Units not saved"
        if (![self.settingsDate.appDate isEqualToString:newDate]) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.postServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
            
            self.settingsDate.appDate = newDate;
            
            [self.postServerProxy setSettingsDate:self.settingsDate];
        }
    }
}

- (void)refreshUI
{
    self.datePicker.hidden = (self.settingsDate == nil);

    if (self.settingsDate) {
        NSDate *date = ([self.settingsDate.appDate length] > 0) ? [self dateFromString:self.settingsDate.appDate] : [NSDate date];
        NSCalendar* cal = [NSCalendar currentCalendar];
        NSDateComponents* dateComp = [cal components:(
                                                      NSHourCalendarUnit |
                                                      NSMinuteCalendarUnit
                                                      )
                                            fromDate:date];

        [super refreshUIWithHour:(int)dateComp.hour minutes:(int)dateComp.minute];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:[error localizedDescription] showErrorMessage:YES];
    
    if (serverProxy == self.pullServerProxy) {
        self.pullServerProxy = nil;
    }
    else if (serverProxy == self.postServerProxy) {
        self.postServerProxy = nil;
    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    
    if (serverProxy == self.pullServerProxy) {

        self.settingsDate = data;
        self.timeFormat = [self.settingsDate.time_format integerValue] == 12 ? 1 : 0;
        
        [super refreshTimeFormatConstraint];
        
        self.pullServerProxy = nil;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    }
    else if (serverProxy == self.postServerProxy) {
        self.postServerProxy = nil;
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.parent handleSprinklerGeneralError:response.message showErrorMessage:YES];
        }
    }
    
    self.separatorLabel.hidden = NO;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self.datePicker reloadAllComponents];
    
    [self refreshUI];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

@end
