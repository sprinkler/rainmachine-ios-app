//
//  ProvisionDateAndTimeVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 23/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "ProvisionDateAndTimeVC.h"
#import "ProvisionDateAndTimeManualVC.h"
#import "MBProgressHUD.h"
#import "ServerProxy.h"
#import "ColoredBackgroundButton.h"
#import "+NSDate.h"

@interface ProvisionDateAndTimeVC ()

@property (strong, nonatomic) ServerProxy *provisionServerProxy;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) ProvisionDateAndTimeManualVC *provisionDateAndTimeManualVC;
@property (strong, nonatomic) IBOutlet ColoredBackgroundButton *buttonSetTimeManually;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *time;

@end

@implementation ProvisionDateAndTimeVC

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleDone target:self action:@selector(onNext:)];
    self.title = @"Date and Time";

    NSDate *now = [NSDate date];

    NSDateFormatter *formatterDate = [NSDate getDateFormaterFixedFormatParsing];
    [formatterDate setDateFormat:@"MM/dd/yy"];

    self.date.text = [formatterDate stringFromDate:now];

    NSDateFormatter *formatterTime = [NSDate getDateFormaterFixedFormatParsing];
    [formatterTime setAMSymbol:@"AM"];
    [formatterTime setPMSymbol:@"PM"];
    [formatterTime setDateFormat:@"hh:mm a"];

    self.time.text = [formatterTime stringFromDate:now];

    [self.buttonSetTimeManually setCustomBackgroundColorFromComponents:kSprinklerBlueColor];
}

- (IBAction)onNext:(id)sender
{
    if (self.locationSetupVC.selectedLocationAddress.location) {
        // self.selectedLocationAddress contains the selected location
        // self.selectedLocationElevation.elevation contains the elevation of the selected location
        // self.selectedLocationTimezone.timeZoneId contains the timezone of the selected location
        self.provisionServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];
        [self.provisionServerProxy setLocation:self.locationSetupVC.selectedLocationAddress.location.coordinate.latitude
                                     longitude:self.locationSetupVC.selectedLocationAddress.location.coordinate.longitude
                                      timezone:[[NSTimeZone localTimeZone] name]];
        
        [self showHud];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.delegate handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.provisionServerProxy) {
    }
    
    [self hideHud];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    
    if (serverProxy == self.provisionServerProxy) {
        //    TODO: handle error code
        [self hideHud];

        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Your Rainmachine was succesfully set up." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
    
    [self hideHud];
}

- (void)loggedOut {
    
    [self hideHud];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"Authentication failed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)showHud {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.view.userInteractionEnabled = NO;
}

- (void)hideHud {
    self.hud = nil;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.view.userInteractionEnabled = YES;
}

- (IBAction)setTimeManually:(id)sender
{
    self.provisionDateAndTimeManualVC = [[ProvisionDateAndTimeManualVC alloc] init];
    UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:self.provisionDateAndTimeManualVC];
    [self.navigationController presentViewController:navDevices animated:YES completion:nil];
}

@end
