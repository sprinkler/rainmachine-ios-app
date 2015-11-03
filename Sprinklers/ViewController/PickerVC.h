//
//  PickerVC.h
//  Sprinklers
//
//  Created by Adrian Manolache on 18/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@interface PickerVC : BaseLevel2ViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) NSArray *itemsArray;
@property (nonatomic, strong) NSArray *itemsDisplayStringArray;
@property (nonatomic, strong) NSString *selectedItem;
@property (nonatomic, strong) NSString *selectedItemTitle;

@property (weak, nonatomic) BaseNetworkHandlingVC<PickerVCDelegate> *parent;

@end
