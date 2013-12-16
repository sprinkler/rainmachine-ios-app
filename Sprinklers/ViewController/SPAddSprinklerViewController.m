//
//  SPAddSprinklerViewController.m
//  Sprinklers
//
//  Created by Fabian Matyas on 03/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SPAddSprinklerViewController.h"
#import "Sprinkler.h"
#import "StorageManager.h"
#import "SPConstants.h"
#import "+UIButton.h"

@interface SPAddSprinklerViewController ()

@end

@implementation SPAddSprinklerViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
  if (indexPath.section == 0) {
    if (self.sprinkler) {
      self.nameTextField.text = self.sprinkler.name;
    }
  }
  else if (indexPath.section == 1) {
    if (self.sprinkler) {
      self.urlOrIPTextField.text = self.sprinkler.address;
    }
  }
  else if (indexPath.section == 3) {
    // Customize the Save button
    cell.backgroundColor = [UIColor clearColor];
    [self.saveButton setupAsRoundColouredButton:[UIColor colorWithRed:kLoginGreenButtonColor[0] green:kLoginGreenButtonColor[1] blue:kLoginGreenButtonColor[2] alpha:1]];
  }

  return cell;
}

#pragma mark - Actions

- (IBAction)onSave:(id)sender {
  NSString *name = self.nameTextField.text;
  NSString *address = self.urlOrIPTextField.text;
  
  if ([address length] == 0) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incomplete fields." message:@"Please provide a value for the IP address" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    return;
  }
  
  if ([name length] == 0) {
    name = address;
  }
  
  if (![address hasPrefix:@"http://"] && ![address hasPrefix:@"https://"]) {
    address = [NSString stringWithFormat:@"https://%@", address];
  }
  
  if ([address hasPrefix:@"http://"]) {
    address = [address stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
  }
  
  if (_sprinkler) {
    _sprinkler.name = self.nameTextField.text;
    _sprinkler.address = self.urlOrIPTextField.text;
    [[StorageManager current] saveData];
    [self.navigationController popViewControllerAnimated:YES];
  }
  else {
    if (![[StorageManager current] getSprinkler:name]) {
      [[StorageManager current] addSprinkler:name ipAddress:address port:0];
      [self.navigationController popViewControllerAnimated:YES];
    } else {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"A sprinkler with the same name already exists. Please select another name." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
      [alert show];
      return;
    }
  }
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField == self.nameTextField) {
    [self.urlOrIPTextField becomeFirstResponder];
  } else {
    if (textField == self.urlOrIPTextField) {
      [self.tokenEmailTextField becomeFirstResponder];
    } else {
      [self.nameTextField becomeFirstResponder];
    }
  }
  
  return YES;
}

# pragma mark - Dealloc

- (void)viewDidUnload {
  
  [self setTableView:nil];
  [super viewDidUnload];
}

@end
