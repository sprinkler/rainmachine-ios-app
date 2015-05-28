//
//  WiFiCel.h
//  Sprinklers
//
//  Created by Fabian Matyas on 03/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WiFiCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *wifiTextLabel;
@property (weak, nonatomic) IBOutlet UIImageView *lockedImageView;
@property (weak, nonatomic) IBOutlet UIImageView *signalImageView;

@end
