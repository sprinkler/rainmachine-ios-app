//
//  ProvisionWiFiVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 01/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProvisionWiFiVC.h"
#import "LabelAndTextFieldCell.h"
#import "SelectWiFiSecurityOptionVC.h"
#import "+UIDevice.h"

@interface ProvisionWiFiVC ()

@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *SSID;
@property (nonatomic, assign) BOOL showSecurity;
@property (nonatomic, assign) BOOL forceShowKeyboard;

@end

@implementation ProvisionWiFiVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.forceShowKeyboard = YES;
    
    self.showSecurity = (self.securityOption == nil);
    if (!self.securityOption) {
        self.securityOption = @"None";
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self.tableView registerNib:[UINib nibWithNibName:@"LabelAndTextFieldCell" bundle:nil] forCellReuseIdentifier:@"LabelAndTextFieldCell"];
    
    self.title = @"Enter Password";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancel)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Join"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(join)];
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
        self.navigationController.navigationBar.translucent = NO;
    }
    else {
        self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
    }

    [self refreshUI];
}

- (void)refreshUI
{
    self.navigationItem.rightBarButtonItem.enabled = self.password.length > 0;
}

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)join
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self.delegate joinWiFi:self.SSID encryption:[self APISecurityOptionFromUIText] key:self.password];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return self.showSSID ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == [self sectionForSSID]) {
        return 1;
    }
    
    if (section == [self sectionForSecurity]) {
        if ([self rowForSecurity] == -1) {
            return 1; // Show only password
        } else {
            return [self.securityOption isEqualToString:@"None"] ? 1 : 2;
        }
    }
    
    return 1;
}

- (int)sectionForSSID
{
    return self.showSSID ? -1 : 0;
}

- (int)sectionForSecurity
{
    return [self sectionForSSID] + 1;
}

- (int)rowForSecurity
{
    return self.showSecurity ? -1 : ([self.securityOption isEqualToString:@"None"] ? -1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    if (indexPath.section == [self sectionForSSID]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"LabelAndTextFieldCell" forIndexPath:indexPath];
        LabelAndTextFieldCell *labelAndTextFieldCell = (LabelAndTextFieldCell*)cell;
        labelAndTextFieldCell.textField.text = self.SSID;
        labelAndTextFieldCell.textField.placeholder = @"Network Name";
        labelAndTextFieldCell.textField.delegate = self;
        labelAndTextFieldCell.textField.secureTextEntry = YES;
        
        if (self.forceShowKeyboard) {
            self.forceShowKeyboard = NO;
            [labelAndTextFieldCell.textField becomeFirstResponder];
        }
    }
    else if (indexPath.section == [self sectionForSecurity]) {
        if (indexPath.row == [self rowForSecurity]) {
            cell =  [tableView dequeueReusableCellWithIdentifier:@"Debug"];
            if (!cell) {
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Debug"];
            }
            cell.selectionStyle = (self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);
            cell.textLabel.text = @"Security";
            cell.detailTextLabel.text = self.securityOption;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else if (indexPath.row == 1) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"LabelAndTextFieldCell" forIndexPath:indexPath];
            LabelAndTextFieldCell *labelAndTextFieldCell = (LabelAndTextFieldCell*)cell;
            labelAndTextFieldCell.textField.text = self.password;
            labelAndTextFieldCell.textField.placeholder = @"";
            labelAndTextFieldCell.textField.delegate = self;

            if (self.forceShowKeyboard) {
                self.forceShowKeyboard = NO;
                [labelAndTextFieldCell.textField becomeFirstResponder];
            }
        }
    }
    
    // Configure the cell...
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == [self sectionForSecurity]) {
        if (indexPath.row == [self rowForSecurity]) {
            SelectWiFiSecurityOptionVC *selectSecurityOptionVC = [[SelectWiFiSecurityOptionVC alloc] initWithDelegate:self];
            selectSecurityOptionVC.selectedIndex = [NSIndexPath indexPathForRow:[SelectWiFiSecurityOptionVC indexForSecurityOption:self.securityOption] inSection:0];

            [self.navigationController pushViewController:selectSecurityOptionVC animated:YES];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSString*)APISecurityOptionFromUIText
{
    if ([self.securityOption isEqualToString:@"None"]) {
        return @"none";
    }
    else if ([self.securityOption isEqualToString:@"PSK"]) {
        return @"psk";
    }
    else if ([self.securityOption isEqualToString:@"PSK2"]) {
        return @"psk2";
    }

    return nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.password = textField.text;
    
    return YES;
}

@end
