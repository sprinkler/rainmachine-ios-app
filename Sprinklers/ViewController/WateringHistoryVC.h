//
//  WateringHistoryVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 24/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"
#import "Protocols.h"
#import <MessageUI/MessageUI.h>

@interface WateringHistoryVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, SprinklerResponseProtocol>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

- (IBAction)onExport:(id)sender;

@end
