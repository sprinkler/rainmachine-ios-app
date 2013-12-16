//
//  SPLoginViewController.m
//  Sprinklers
//
//  Created by Fabian Matyas on 03/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SPLoginViewController.h"
#import "Sprinkler.h"
#import "+UIButton.h"
#import "SPConstants.h"
#import "SPServerProxy.h"
#import "MBProgressHUD.h"
#import "SPMainScreenViewController.h"
#import "StorageManager.h"

@interface SPLoginViewController ()

@end

@implementation SPLoginViewController

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
  
  // iOS7 views go under the navigation bar, you can stop your views going under the navigation bar in your viewController
  // This will allow overlayView to correctly cover only the usable view part and not the navigation bar.
//  self.edgesForExtendedLayout = UIRectEdgeNone;
  
  [self setupTitleView];

  [self.checkBox setBackgroundImage:[UIImage imageNamed:@"temp-checkbox-unselected"] forState:UIControlStateNormal];
  [self.checkBox setBackgroundImage:[UIImage imageNamed:@"temp-checkbox-selected"] forState:UIControlStateSelected];
  [self.checkBox setBackgroundImage:[UIImage imageNamed:@"temp-checkbox-selected"] forState:UIControlStateHighlighted];
  self.checkBox.adjustsImageWhenHighlighted = YES;
  [self.checkBox addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchUpInside];

  [self.loginButton setupAsRoundColouredButton:[UIColor colorWithRed:kLoginGreenButtonColor[0] green:kLoginGreenButtonColor[1] blue:kLoginGreenButtonColor[2] alpha:1]];
  
  self.tableView.sectionFooterHeight = 0;
  self.tableView.sectionHeaderHeight = 0;
  
  if ([self.sprinkler.loginRememberMe boolValue]) {
    [self showMainScreen];
  }
}

- (void)viewWillAppear:(BOOL)animated
{
  [self.checkBox setSelected:[self.sprinkler.loginRememberMe boolValue]];
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  self.alertView = nil;
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
  cell.backgroundColor = [UIColor clearColor];
  return cell;
}

#pragma mark - Actions

- (IBAction)onLogin:(id)sender {
  self.serverProxy = [[SPServerProxy alloc] initWithServerURL:SPTestServerURL delegate:self jsonRequest:NO];
  
  [self.serverProxy loginWithUserName:@"admin" password:self.passwordTextField.text rememberMe:self.checkBox.isSelected];
  [self startHud:@"Logging in..."];
}

-(void)checkboxSelected:(id)sender
{
  [self.checkBox setSelected:!self.checkBox.isSelected];
}

#pragma mark - UI

- (void)setupTitleView
{
  self.deviceNameLabel.text = self.sprinkler.name;
  self.deviceIPLabel.text = self.sprinkler.address;
  
  self.deviceNameLabel.textColor = [UIColor whiteColor];
  self.deviceIPLabel.textColor = [UIColor lightGrayColor];
}

- (void)startHud:(NSString *)text {
//  self.loadingOverlay = [[UIView alloc] initWithFrame:self.view.bounds];
//  self.loadingOverlay.backgroundColor = [UIColor clearColor];
//  self.loadingOverlay.userInteractionEnabled = NO;
//  [self.view addSubview:self.loadingOverlay];
//  self.loadingOverlay.hidden = NO;
  self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  self.hud.labelText = text;
  self.view.userInteractionEnabled = NO;
}

- (void)hideHud {
//  self.loadingOverlay = nil;
//  self.loadingOverlay.hidden = YES;
  [MBProgressHUD hideHUDForView:self.view animated:YES];
  self.view.userInteractionEnabled = YES;
}

- (void)showMainScreen
{
  UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
  
  // Give your view an identifier in the storyboard. That's how the storyboard object will find it.
  // You should see it in the right panel options when you click on the view.
  SPMainScreenViewController *mainScreenController = (SPMainScreenViewController*)[storyboard instantiateViewControllerWithIdentifier:@"mainScreen"];
  mainScreenController.sprinkler = self.sprinkler;
  [self.navigationController pushViewController:mainScreenController animated:YES];
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy
{
  [self hideHud];
  self.alertView = [[UIAlertView alloc] initWithTitle:@"Network error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
  [self.alertView show];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy
{
  [self hideHud];
}

- (void)loginSucceeded
{
  self.sprinkler.loginRememberMe = [NSNumber numberWithBool:self.checkBox.selected];
  [[StorageManager current] saveData];

  [self hideHud];

  [self showMainScreen];
}

- (void)loggedOut
{
  [self hideHud];
  self.alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"Your password is incorrect." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
  [self.alertView show];
}

#pragma  mark - TextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

#pragma  mark - Dealloc

- (void)viewDidUnload {
  [self setTableView:nil];
//  self.loadingOverlay = nil;
  self.hud = nil;
  [super viewDidUnload];
}

@end
