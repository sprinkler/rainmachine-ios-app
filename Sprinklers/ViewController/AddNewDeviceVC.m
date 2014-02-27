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
#import "Utils.h"
#import "+UIDevice.h"

@interface AddNewDeviceVC ()

@property (weak, nonatomic) IBOutlet UITextField *urlOrIPTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *tokenEmailTextField;
@property (weak, nonatomic) IBOutlet ColoredBackgroundButton *saveButton;
@property (weak, nonatomic) IBOutlet UILabel *tokenExplanationTextfield;
@property (weak, nonatomic) IBOutlet UIImageView *tokenSeparator;
@property (weak, nonatomic) IBOutlet UIImageView *nameAndUrlSeparator;
@property (weak, nonatomic) IBOutlet UILabel *tokenTitleLabel;

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

    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        _nameTextField.tintColor = _nameTextField.textColor;
        _urlOrIPTextField.tintColor = _urlOrIPTextField.textColor;
        _tokenEmailTextField.tintColor = _tokenEmailTextField.textColor;
    }

    [self removeTokenView];
    
    // Customize the Save button
    [self.saveButton setCustomBackgroundColorFromComponents:kLoginGreenButtonColor];

    [_nameTextField becomeFirstResponder];
}

- (void)removeTokenView
{
    [_tokenExplanationTextfield removeFromSuperview];
    [_nameAndUrlSeparator removeFromSuperview];
    [_tokenTitleLabel removeFromSuperview];
    [_tokenEmailTextField removeFromSuperview];
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_tokenSeparator
                                                                   attribute:NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:_urlOrIPTextField
                                                                   attribute:NSLayoutAttributeBottom
                                                                  multiplier:1.0
                                                                    constant:18.0];

    constraint.priority = UILayoutPriorityRequired;
    
    [self.view addConstraint:constraint];
}

#pragma mark - Actions

- (IBAction)onSave:(id)sender {
    NSString *name = self.nameTextField.text;
    NSString *address = [Utils fixedSprinklerAddress:self.urlOrIPTextField.text];
    NSURL *url = [NSURL URLWithString:address];
    NSString *port = [[url port] stringValue];
    
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
    
    if (!port) {
        port = @"443";
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
