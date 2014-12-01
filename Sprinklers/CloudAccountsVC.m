//
//  CloudAccountsVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 19/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "CloudAccountsVC.h"
#import "CloudEmailDevicesVC.h"
#import "AddNewCell.h"
#import "Constants.h"
#import "+UILabel.h"
#import "AddNewDeviceVC.h"
#import "CloudUtils.h"

@interface CloudAccountsVC ()

@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (strong, nonatomic) NSMutableDictionary *cloudResponsePerEmails;

@end

@implementation CloudAccountsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Cloud";
    
    self.editBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(edit:)];
    self.navigationItem.rightBarButtonItem = self.editBarButtonItem;

    NSArray *sprinklersByEmail = self.cloudResponse[@"sprinklersByEmail"];
    self.cloudResponsePerEmails = [NSMutableDictionary new];
    for (NSDictionary *cloudD in sprinklersByEmail) {
        self.cloudResponsePerEmails[cloudD[@"email"]] = cloudD;
    }
    [self.tableView registerNib:[UINib nibWithNibName:@"AddNewCell" bundle:nil] forCellReuseIdentifier:@"AddNewCell"];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSDictionary *cloudAccounts = [CloudUtils cloudAccounts];
    self.cloudEmails = [[cloudAccounts allKeys] mutableCopy];

    [self.tableView reloadData];
}

- (IBAction)edit:(id)sender {
    [self.tableView setEditing:!self.tableView.editing];
    if (self.tableView.editing) [self.editBarButtonItem setTitle:@"Done"];
    else [self.editBarButtonItem setTitle:@"Edit"];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0) {
        return self.cloudEmails.count;
    }
    
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:@"Debug"];
        if (!cell) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Debug"];
        }
        
        cell.textLabel.text = self.cloudEmails[indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        NSDictionary *details = self.cloudResponsePerEmails[cell.textLabel.text];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"activeCount:%d knownCount:%d authCount:%d",
                                     [details[@"activeCount"] intValue],
                                     [details[@"knownCount"] intValue],
                                     [details[@"authCount"] intValue]];
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        
        return cell;
    }

    // Add Cloud Account
    AddNewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddNewCell" forIndexPath:indexPath];
    cell.selectionStyle = (self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);
    [cell.plusLabel setCustomRMFontWithCode:icon_Add size:24];
    
    [cell.plusLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
    [cell.titleLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
    
    cell.titleLabel.text = @"Add cloud account";

    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return indexPath.section == 0;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [CloudUtils deleteCloudAccountWithEmail:self.cloudEmails[indexPath.row]];
        [self.cloudEmails removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


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
    if (indexPath.section == 0) {
        // Navigation logic may go here, for example:
        // Create the next view controller.
        CloudEmailDevicesVC *detailViewController = [[CloudEmailDevicesVC alloc] init];
        NSString *email = self.cloudEmails[indexPath.row];
        detailViewController.devices = self.cloudSprinklers[email];
        detailViewController.email = email;
        // Pass the selected object to the new view controller.
        
        // Push the view controller.
        [self.navigationController pushViewController:detailViewController animated:YES];
    } else {
        AddNewDeviceVC *addNewDeviceVC = [[AddNewDeviceVC alloc] init];
        addNewDeviceVC.cloudUI = YES;
        [self.navigationController pushViewController:addNewDeviceVC animated:YES];
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
