//
//  DevicesVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "Protocols.h"
#import "TRPickerInputView.h"

@interface DevicesVC : BaseViewController <UITableViewDataSource, UITableViewDelegate, SprinklerResponseProtocol, TRPickerInputViewDataSource, TRPickerInputViewDelegate>

- (void)done:(NSString*)unit;
- (void)startHud:(NSString*)text;

@end
