//
//  DevicesMenuVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 04/05/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseViewController.h"

@interface DevicesMenuVC : BaseViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSDictionary *cloudResponse;
@property (strong, nonatomic) NSMutableArray *cloudEmails;
@property (strong, nonatomic) NSDictionary *cloudSprinklers;
@property (strong, nonatomic) NSArray *manuallyEnteredSprinkler;

@end
