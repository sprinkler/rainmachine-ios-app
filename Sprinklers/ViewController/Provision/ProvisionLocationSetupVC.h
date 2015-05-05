//
//  LocationSetupVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "DiscoveredSprinklers.h"
#import "Protocols.h"
#import "BaseWizardVC.h"
#import "Sprinkler.h"
#import "GoogleAddress.h"

@class ColoredBackgroundButton;

@interface ProvisionLocationSetupVC : BaseWizardVC <GMSMapViewDelegate, SprinklerResponseProtocol, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar *locationSearchBar;
@property (nonatomic, weak) IBOutlet UIView *mapContentView;
@property (nonatomic, weak) IBOutlet GMSMapView *mapView;
@property (strong, nonatomic) DiscoveredSprinklers *sprinkler;
@property (strong, nonatomic) Sprinkler *dbSprinkler;

//@property (nonatomic, weak) BaseNetworkHandlingVC *delegate;
@property (nonatomic, strong) GoogleAddress *selectedLocationAddress;

- (IBAction)onSave:(id)sender;
- (IBAction)onSkipLocation:(id)sender;

@end
