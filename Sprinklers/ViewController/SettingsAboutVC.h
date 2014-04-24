//
//  SettingsAboutVC.h
//  Sprinklers
//
//  Created by Adrian Manolache on 04/04/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"

@interface SettingsAboutVC : UIViewController<UpdateManagerDelegate>
{
    IBOutlet UILabel* iosVersion;
    IBOutlet UILabel* hwVersion;
}

@end
