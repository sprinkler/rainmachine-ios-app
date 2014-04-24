//
//  UpdaterVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 30/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "UpdaterVC.h"
#import "ServerProxy.h"
#import "UpdateInfo.h"
#import "Constants.h"
#import "Additions.h"
#import "Utils.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "UpdateManager.h"

@interface UpdaterVC ()

@property (nonatomic, strong) NSTimer *timer;
@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) NSDate *startDate;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation UpdaterVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Firmware update";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view.

    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1];
        self.navigationController.navigationBar.translucent = NO;
    }

    self.serverProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
    self.startDate = [NSDate date];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(poll) userInfo:nil repeats:YES];
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;   
}

- (void)onDone
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)poll
{
    NSTimeInterval since = -[self.startDate timeIntervalSinceNow];
    if (since > kUpdateProcessTimeoutInterval) {
        [self.activityIndicator stopAnimating];
        self.activityIndicator.hidden = YES;
        [self stopTimer];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Timeout"
                                                        message:@"The firmware update timed out." delegate:self cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        alert.tag = kAlertView_Timeout;
    } else {
        [self.serverProxy cancelAllOperations];
        [self.serverProxy requestUpdateCheckForVersion:self.serverAPIMainVersion];
    }
}

#pragma mark - Server responses

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy userInfo:(id)userInfo
{
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    if ([data isKindOfClass:[UpdateInfo class]]) {
        UpdateInfo *updateInfo = (UpdateInfo*)data;
        BOOL updateFinished = NO;
        BOOL wasError = NO;

        if (updateInfo.update) {
            if ([updateInfo.update boolValue] == NO) { // update: false
                if (([updateInfo.update_status intValue] == 0) || (!updateInfo.update_status)) { // update_status : 0 or missing
                    updateFinished = YES;
                } else {
                    if ((updateInfo.update_status) && ([updateInfo.update_status intValue] == 0)) {
                        // update_status == 0 it means we have an error
                        updateFinished = YES;
                        wasError = YES;
                    }
                }
            }
        } else {
            // During update we receive update_status: 1 if things go normally, and 0 if error
            if ((updateInfo.update_status) && ([updateInfo.update_status intValue] == 0)) {
                // update_status == 0 it means we have an error
                updateFinished = YES;
                wasError = YES;
            }
        }
        
        if (updateFinished) {
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = YES;
            [self stopTimer];
            UIAlertView *alert;
            if (wasError) {
                alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                   message:@"The firmware update encounter an error during installing!" delegate:self cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
            } else {
                // Update AppDelegate's sprinkler version
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                NSArray *versionComponents = [updateInfo.the_new_version componentsSeparatedByString:@"."];
                appDelegate.updateManager.serverAPIMainVersion = [versionComponents[0] intValue];
                appDelegate.updateManager.serverAPISubVersion = [versionComponents[1] intValue];

                alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                message:@"The firmware update has been succesfully installed." delegate:self cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            }
            alert.tag = kAlertView_Finished;
            [alert show];
        }
    }
}

- (void)loggedOut
{
}

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (theAlertView.tag == kAlertView_Timeout) {
        [self stopTimer];
    }
    else if (theAlertView.tag == kAlertView_Finished) {
        [self stopTimer];
    }
    
    // Poll again the sprinkler version to be sure we are up to date
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.updateManager poll:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
