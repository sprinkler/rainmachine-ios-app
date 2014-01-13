//
//  RainDelayVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 08/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RainDelayVC.h"
#import "Additions.h"
#import "ColoredBackgroundButton.h"
#import "Constants.h"

@interface RainDelayVC ()

@property (strong, nonatomic) IBOutlet UILabel *labelDays;
@property (weak, nonatomic) IBOutlet UIButton *buttonUp;
@property (weak, nonatomic) IBOutlet UIButton *buttonDown;
@property (strong, nonatomic) IBOutlet ColoredBackgroundButton *buttonSety;
@end

@implementation RainDelayVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Rain Delay";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.buttonUp setCustomRMFontWithCode:icon_Up size:90];
    [self.buttonDown setCustomRMFontWithCode:icon_Down size:90];
    
    [_buttonSety setCustomBackgroundColorFromComponents:kLoginGreenButtonColor];
}

- (IBAction)up:(id)sender {
}

- (IBAction)down:(id)sender {
}

- (IBAction)set:(id)sender {
}

@end
