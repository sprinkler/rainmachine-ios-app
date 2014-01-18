//
//  PickerVC.h
//  Sprinklers
//
//  Created by Adrian Manolache on 18/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
    
@interface PickerVC : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate>
{   
}

@property (nonatomic, retain) IBOutlet UIPickerView *pickerView;
@property (nonatomic, retain) NSMutableArray *dataArray;

@end
