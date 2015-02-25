//
//  DatePickerVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 03/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "DatePickerVC.h"
#import "SettingsDate.h"
#import "MBProgressHUD.h"
#import "ServerProxy.h"
#import "ServerResponse.h"
#import "SettingsVC.h"
#import "Utils.h"
#import "+UIDevice.h"
#import "+NSDate.h"

@interface DatePickerVC ()
//{
//    NSInteger hours;
//    NSInteger minutes;
//}

@property (strong, nonatomic) SettingsDate *settingsDate;
@property (strong, nonatomic) ServerProxy *pullServerProxy;
@property (strong, nonatomic) ServerProxy *postServerProxy;

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalConstraint;

@end

@implementation DatePickerVC

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
    
    if (![[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.view.backgroundColor = [UIColor blackColor];
        
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.datePicker
                                                                      attribute:NSLayoutAttributeTop
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeTop
                                                                     multiplier:1.0
                                                                       constant:0];
        
        [self.view removeConstraint:self.verticalConstraint];
        [self.view addConstraint:constraint];
    }
    
    self.title = @"Date";
}

- (NSDate*)dateFromString:(NSString*)stringDate timeFormat:(NSNumber*)timeFormat
{
    return [[Utils sprinklerDateFormatterForTimeFormat:timeFormat] dateFromString:stringDate];
}

- (NSString*)stringFromDate:(NSDate*)date seconds:(BOOL)seconds
{
    return [[Utils sprinklerDateFormatterForTimeFormat:self.settingsDate.time_format seconds:seconds] stringFromDate:date];
}

- (NSDate*)constructDateFromPicker
{
    NSDate *date;
    if ([self.settingsDate.appDate length] > 0) {
        date = [self dateFromString:self.settingsDate.appDate timeFormat:self.settingsDate.time_format];
    } else {
        date = [NSDate date];
    }
    NSCalendar* timeCal = [NSCalendar currentCalendar];
    NSDateComponents* timeComp = [timeCal components:(
                                                      NSHourCalendarUnit |
                                                      NSMinuteCalendarUnit
                                                      )
                                            fromDate:date];
    
    NSCalendar* dateCal = [NSCalendar currentCalendar];
    NSDateComponents* dateComp = [dateCal components:(
                                                      NSMonthCalendarUnit |
                                                      NSYearCalendarUnit |
                                                      NSDayCalendarUnit
                                                      )
                                            fromDate:self.datePicker.date];
    
    dateComp.hour = timeComp.hour;
    dateComp.minute = timeComp.minute;
    
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
    if (self.settingsDate) {
        NSNumber *timeFormat = self.settingsDate.time_format;
        NSDate *date;
        if ([self.settingsDate.appDate length] > 0) {
            date = [self dateFromString:self.settingsDate.appDate timeFormat:timeFormat];
        } else {
            date = [NSDate date];
        }
        
        if (!date) {
            // Starting form Sprinkler v3.59 the comes in am/pm format regardless of time_format
            // This is a workaround for that case
            int fixedTimeFormat = ([timeFormat intValue] == 24) ? 12 : 24;
            date = [self dateFromString:self.settingsDate.appDate timeFormat:[NSNumber numberWithInt:fixedTimeFormat]];
        }
        
        if (date) {
            [self.datePicker setDate:date animated:NO];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Couldn't parse date" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            
            self.settingsDate = nil;
        }
    }

    self.datePicker.hidden = (self.settingsDate == nil);
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
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self refreshUI];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

@end
