//
//  AddSprinklerViewController_iPhone.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/17/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "AddSprinklerViewController_iPhone.h"
#import "StorageManager.h"
#import "Additions.h"

@implementation AddSprinklerViewController_iPhone

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Add Sprinkler";
        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
        self.navigationItem.rightBarButtonItem = saveButton;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    if (_sprinkler) {
        self.title = @"Edit Sprinkler";
    } else {
        self.title = @"Add Sprinkler";
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:@"ApplicationDidBecomeActive" object:nil];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    int section = 1;
    if (textField.tag == 2) section = 0;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    UIView *view = [cell viewWithTag:section + 1];
    [view becomeFirstResponder];

    return YES;
}

#pragma mark - Actions

- (void)appDidBecomeActive {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (NSString *)getValue:(int)section {
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    if (cell) {
        UITextField *view = (UITextField *)[cell viewWithTag:section + 1];
        return view.text;
    }
    return @"";
}

- (IBAction)save:(id)sender {
    NSString *name = [self getValue:0];
    NSString *address = [self getValue:1];
    
    if ([NSString isEmpty:address]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incomplete fields." message:@"Please provide a value for the IP address" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    if ([NSString isEmpty:name]) {
        name = address;
    }
    
    if (![address hasPrefix:@"http://"] && ![address hasPrefix:@"https://"]) {
        address = [NSString stringWithFormat:@"https://%@", address];
    }
    
    if ([address hasPrefix:@"http://"]) {
        address = [address stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
    }
    
    if (_sprinkler) {
        _sprinkler.name = [self getValue:0];;
        _sprinkler.address = [self getValue:1];
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

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"Name";
    if (section == 1)
        return @"Address";
    
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    UITextField *text = [[UITextField alloc] initWithFrame:CGRectMake(5, 10, 290, 30)];
    text.returnKeyType = UIReturnKeyDone;
    text.autocorrectionType = UITextAutocorrectionTypeNo;
    text.clearButtonMode = UITextFieldViewModeWhileEditing;
    text.delegate = self;
    text.tag = indexPath.section + 1;
    
    // remove existing content
    for (UIView *view in cell.contentView.subviews)
        [view removeFromSuperview];

    if (indexPath.section == 0) {
        text.placeholder = @"Type the sprinkler's name here.";
        if (_sprinkler) {
            text.text = _sprinkler.name;
        }
    }
    if (indexPath.section == 1) {
        text.placeholder = @"Type the sprinkler's URL here.";
        if (_sprinkler) {
            text.text = _sprinkler.address;
        }
    }
    
    [cell.contentView addSubview:text];
    return cell;
}

#pragma mark - Dealloc

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {

    [self setTableView:nil];
    [super viewDidUnload];
}

@end
