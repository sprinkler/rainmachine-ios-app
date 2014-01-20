//
//  PickerVC.m
//  Sprinklers
//
//  Created by Adrian Manolache on 18/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "PickerVC.h"

@interface PickerVC ()
    
@end

@implementation PickerVC

@synthesize pickerView;
@synthesize dataArray;

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
    
    // Init the data array.
    dataArray = [[NSMutableArray alloc] init];
    
    // Add some data for demo purposes.
    for (int i=0; i<=10; i++)
        [dataArray addObject: [NSString stringWithFormat: @"%d C", i]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Number of components.
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

// Total rows in our component.
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [dataArray count];
}

// Display each row's data.
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [dataArray objectAtIndex: row];
}

// Do something with the selected row.
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    NSLog(@"You selected this: %@", [dataArray objectAtIndex: row]);
}

@end
