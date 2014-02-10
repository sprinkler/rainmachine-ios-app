//
//  ZonePropertiesVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 09/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ZonePropertiesVC.h"
#import "Additions.h"
#import "EditCell.h"
#import "MBProgressHUD.h"
#import "ServerProxy.h"
#import "ColoredBackgroundButton.h"
#import "Utils.h"

typedef enum {
    MasterValve = 0,
    Active = 1,
    VegetationType = 2,
    Advanced = 3,
    ForecastData = 4,
    HistoricalAverages = 5
} RowTypes;

@interface ZonePropertiesVC () {
    MBProgressHUD *hud;
}

@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) ServerProxy *postServerProxy;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet ColoredBackgroundButton *buttonRunNow;

@end

@implementation ZonePropertiesVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (_zone) {
        self.title = _zone.name;
    }
    
    self.serverProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    self.postServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButton;
       
    [_buttonRunNow setCustomBackgroundColorFromComponents:kLoginGreenButtonColor];
    
    [_tableView registerNib:[UINib nibWithNibName:@"EditCell" bundle:nil] forCellReuseIdentifier:@"EditCell"];
}

#pragma mark - Actions

- (IBAction)runNow:(id)sender {
}

- (void)switchChanged:(UISwitch *)sw {
    int tag = sw.tag;
    if (tag == MasterValve) {
        _zone.masterValve = !_zone.masterValve;
    }
    if (tag == Active) {
        _zone.active = !_zone.active;
    }
    if (tag == ForecastData) {
        _zone.forecastData = !_zone.forecastData;
    }
    if (tag == HistoricalAverages) {
        _zone.historicalAverage = !_zone.historicalAverage;
    }
}

- (NSString *)getVegetationType:(int)type {
    switch (type) {
        case 0:
            return @"Bushes";
        case 1:
            return @"Grass";
        case 2:
            return @"Magic Beans";
        case 3:
            return @"Dog shit";
        case 4:
            return @"Trees";
        default:
            return @"Trees";
            break;
    }
}

- (void)save {
    [self startHud:nil];
    [self.serverProxy saveZone:_zone];
}

- (void)startHud:(NSString *)text {
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    _zone.name = textField.text;
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_zone) {
        if (section == 0 && _showMasterValve) {
            return 1;
        }
        if (section == 1) {
            return 6;
        }
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    return view;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 35)];
    headerView.backgroundColor = [UIColor colorWithRed:229.0f / 255.0f green:229.0f / 255.0f blue:229.0f / 255.0f alpha:1.0f];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.textLabel.text = @"Master Valve";
        cell.tag = MasterValve;
        UISwitch *sw = [[UISwitch alloc] init];
        sw.on = _zone.masterValve;
        sw.tag = MasterValve;
        [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
        return cell;
    }
    
    if (indexPath.row == 0) {
        EditCell *cell = (EditCell *)[tableView dequeueReusableCellWithIdentifier:@"EditCell"];

        cell.textTitle.delegate = self;
        cell.textTitle.text = _zone.name;
        
        return cell;
    }
    
    if (indexPath.row == 1) {
        static NSString *CellIdentifier1 = @"Cell1";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1];
        }
        UISwitch *sw = [[UISwitch alloc] init];
        sw.on = _zone.active;
        sw.tag = Active;
        [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
        cell.textLabel.text = @"Active";
        return cell;
    }
    
    if (indexPath.row == 2) {
        static NSString *CellIdentifier2 = @"Cell2";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
        
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier2];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        cell.textLabel.text = @"Vegetation Type";
        cell.detailTextLabel.text = [self getVegetationType:_zone.vegetation];
        
        
        return cell;
    }

    if (indexPath.row == 3) {
        static NSString *CellIdentifier3 = @"Cell3";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier3];
        
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier3];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }

        cell.textLabel.text = @"Advanced";
        return cell;
    }

    if (indexPath.row == 4) {
        static NSString *CellIdentifier4 = @"Cell4";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier4];
        
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier4];
        }
        UISwitch *sw = [[UISwitch alloc] init];
        sw.on = _zone.forecastData;
        sw.tag = ForecastData;
        [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
        cell.textLabel.text = @"Forecast Data";
        return cell;
    }

    if (indexPath.row == 5) {
        static NSString *CellIdentifier5 = @"Cell5";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier5];
        
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier5];
        }
        UISwitch *sw = [[UISwitch alloc] init];
        sw.on = _zone.historicalAverage;
        sw.tag = HistoricalAverages;
        [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
        cell.textLabel.text = @"Historical Averages";
        return cell;
    }
    
    return nil;
}

@end
