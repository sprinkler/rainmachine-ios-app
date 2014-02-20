//
//  AddNewDeviceVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "AddNewDeviceVC.h"
#import "Sprinkler.h"
#import "StorageManager.h"
#import "Constants.h"
#import "ColoredBackgroundButton.h"

@interface AddNewDeviceVC ()

@property (weak, nonatomic) IBOutlet UITextField *urlOrIPTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *tokenEmailTextField;
@property (weak, nonatomic) IBOutlet ColoredBackgroundButton *saveButton;

@end

@implementation AddNewDeviceVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Add New Device";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    if (self.sprinkler) {
        self.nameTextField.text = self.sprinkler.name;
        self.urlOrIPTextField.text = self.sprinkler.address;
    }

    // Customize the Save button
    [self.saveButton setCustomBackgroundColorFromComponents:kLoginGreenButtonColor];
}

#pragma mark - Actions

- (IBAction)onSave:(id)sender {
    NSString *name = self.nameTextField.text;
    NSString *address = self.urlOrIPTextField.text;
    NSString *port;
    NSArray *array = [address componentsSeparatedByString:@":"];
    NSInteger lengthOfAdress = [array count] -1;
    
    if(lengthOfAdress >= 1)
    {
        port = array[lengthOfAdress];
    }
    
    // if we type adress:port port must have under 4 digits (otherwise it means we have something like https://adress and we don't have a port)
    if(lengthOfAdress == 1)
    {
        if([array[1] length] > 4)
            port = NULL;
    }
    
    
    if ([address length] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incomplete fields." message:@"Please provide a value for the IP address" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    if ([port length] > 0) {
        if ([port length] + 1  < [address length]) {
            address = [address substringToIndex:[address length] - ([port length] + 1)];
        }
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
        _sprinkler.name = name;
        _sprinkler.address = address;
        _sprinkler.port = port;
        [[StorageManager current] saveData];
        [self.navigationController popViewControllerAnimated:YES];
        
    }
    else {
        if (![[StorageManager current] getSprinkler:name local:@NO]) {
            [[StorageManager current] addSprinkler:name ipAddress:address port:port isLocal:@NO save:YES];
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
    if ((textField == self.nameTextField) ||
        (textField == self.tokenEmailTextField) ||
        (textField == self.urlOrIPTextField)
        ) {
        [textField resignFirstResponder];
        
        return YES;
    }
    
    return NO;
}

#pragma mark - Dealloc

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
