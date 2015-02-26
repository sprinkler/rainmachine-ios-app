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
#import "+NSDate.h"

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
    self.pullServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.pullServerProxy requestSettingsDate];

    [self refreshUI];
    
    self.title = @"Time";
    
    self.timeFormat = [Utils timeIs24HourFormat] ? 0 : 1;
    [super refreshTimeFormatConstraint];
}

- (NSDate*)dateFromString:(NSString*)stringDate
{
    return [[Utils sprinklerDateFormatterForTimeFormat:self.settingsDate.time_format] dateFromString:stringDate];
}

- (NSString*)stringFromDate:(NSDate*)date seconds:(BOOL)seconds
{
    return [[Utils sprinklerDateFormatterForTimeFormat:self.settingsDate.time_format seconds:seconds] stringFromDate:date];
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
        
        NSString *newDate = [self stringFromDate:[self constructDateFromPicker] seconds:NO];
        NSString *newDateToStore = [self stringFromDate:[self constructDateFromPicker] seconds:YES];
        
        // If we save the same unit again the server returns error: "Units not saved"
        if (![self.settingsDate.appDate isEqualToString:newDate]) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.postServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
            
            self.settingsDate.appDate = newDate;
            
            [self.postServerProxy setSettingsDate:self.settingsDate];
            
            // Sprinkler sends times with seconds. Store it the same way.
            self.settingsDate.appDate = newDateToStore;
        }
    }
}

- (void)refreshUI
{
    self.datePicker.hidden = (self.settingsDate == nil);
    self.separatorLabel.hidden = self.datePicker.hidden;

    if (self.settingsDate) {
        NSDate *date = ([self.settingsDate.appDate length] > 0) ? [self dateFromString:self.settingsDate.appDate] : [NSDate date];
        if (date) {
            NSCalendar* cal = [NSCalendar currentCalendar];
            NSDateComponents* dateComp = [cal components:(
                                                          NSHourCalendarUnit |
                                                          NSMinuteCalendarUnit
                                                          )
                                                fromDate:date];

            [super refreshUIWithHour:(int)dateComp.hour minutes:(int)dateComp.minute];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Couldn't parse date" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            
            self.settingsDate = nil;
        }
    }
    
    self.datePicker.hidden = (self.settingsDate == nil);
    self.separatorLabel.hidden = (self.settingsDate == nil);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.pullServerProxy) {
        self.pullServerProxy = nil;
    }
    else if (serverProxy == self.postServerProxy) {
    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    
    if (serverProxy == self.pullServerProxy) {

        self.settingsDate = data;
//        self.timeFormat = [self.settingsDate.time_format integerValue] == 12 ? 1 : 0;

        [super refreshTimeFormatConstraint];
        
        self.pullServerProxy = nil;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    }
    else if (serverProxy == self.postServerProxy) {
        self.postServerProxy = nil;
        NSString *errorMessage = nil;
        if ([ServerProxy usesAPI3]) {
            ServerResponse *response = (ServerResponse*)data;
            if ([response.status isEqualToString:@"err"]) {
                errorMessage = response.message;
            }
        }
        if (errorMessage) {
            [self.parent handleSprinklerGeneralError:errorMessage showErrorMessage:YES];
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
