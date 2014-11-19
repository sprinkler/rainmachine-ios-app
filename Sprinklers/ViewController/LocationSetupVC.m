//
//  LocationSetupVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "LocationSetupVC.h"
#import "ColoredBackgroundButton.h"
#import "Constants.h"
#import "Additions.h"
#import "GeocodingAddress.h"
#import "GeocodingAutocompletePrediction.h"
#import "GeocodingRequest.h"
#import "GeocodingRequestReverse.h"
#import "GeocodingRequestAutocomplete.h"
#import "MBProgressHUD.h"
#import <CoreLocation/CoreLocation.h>

const double LocationSetup_MapView_InitializeTimeout                = 5.0;
const double LocationSetup_MapView_StartRegionSizeMeters            = 1000.0;
const double LocationSetup_Autocomplete_ReloadResultsTimeInterval   = 0.5;

#pragma mark -

@interface LocationSetupVC ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSDate *autocompleteReloadResultsDate;
@property (nonatomic, strong) NSString *autocompleteSearchString;
@property (nonatomic, strong) NSArray *autocompletePredictions;
@property (nonatomic, strong) GeocodingRequestAutocomplete *autocompleteRequest;

- (BOOL)initializeLocationServices;
- (void)displayLocationServicesDisabledAlert;

@property (nonatomic, assign) BOOL startLocationFound;
@property (nonatomic, strong) GeocodingAddress *selectedLocation;
@property (nonatomic, strong) GMSMarker *selectedLocationMarker;

- (void)markSelectedLocationAnimated:(BOOL)animate;
- (NSString*)displayStringForLocation:(GeocodingAddress*)location;

@end

#pragma mark -

@implementation LocationSetupVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;
    
    self.title = @"Location";
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleDone target:self action:@selector(onNext:)];
    
    if (![self initializeLocationServices]) {
        [self displayLocationServicesDisabledAlert];
        return;
    }
    
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = YES;
    self.mapView.settings.myLocationButton = YES;
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self performSelector:@selector(hideHUDAddedToView) withObject:nil afterDelay:LocationSetup_MapView_InitializeTimeout];
}

- (void)hideHUDAddedToView {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.mapView addObserver:self forKeyPath:@"myLocation" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.startLocationFound) {
        [self.mapView removeObserver:self forKeyPath:@"myLocation"];
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (object == self.mapView && [keyPath isEqualToString:@"myLocation"] && !self.startLocationFound) {
        self.startLocationFound = YES;
        [self.mapView removeObserver:self forKeyPath:@"myLocation"];
        
        float zoom = [GMSCameraPosition zoomAtCoordinate:self.mapView.myLocation.coordinate
                                               forMeters:LocationSetup_MapView_StartRegionSizeMeters
                                               perPoints:self.mapView.bounds.size.width];
        
        [self.mapView animateToCameraPosition:[GMSCameraPosition cameraWithLatitude:self.mapView.myLocation.coordinate.latitude
                                                                          longitude:self.mapView.myLocation.coordinate.longitude
                                                                               zoom:zoom]];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideHUDAddedToView) object:nil];
        [[GeocodingRequestReverse reverseGeocodingRequestWithLocation:self.mapView.myLocation] executeRequestWithCompletionHandler:^(GeocodingAddress *result, NSError *error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            if (!error) {
                self.selectedLocation = result;
                self.locationSearchBar.placeholder = [self displayStringForLocation:self.selectedLocation];
                [self markSelectedLocationAnimated:YES];
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper methods

- (BOOL)initializeLocationServices {
    if (![CLLocationManager locationServicesEnabled]) return NO;
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    return YES;
}

- (void)displayLocationServicesDisabledAlert {
    if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Location Services disabled"
                                                                                 message:@"Allow RainMachine to access your location in your phone's settings."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Location Services disabled"
                                                            message:@"Allow RainMachine to access your location in your phone's settings."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)markSelectedLocationAnimated:(BOOL)animate {
    if (!self.selectedLocation) return;
    
    self.selectedLocationMarker.map = nil;
    self.selectedLocationMarker = [GMSMarker markerWithPosition:self.selectedLocation.location.coordinate];
    self.selectedLocationMarker.title = [self displayStringForLocation:self.selectedLocation];
    self.selectedLocationMarker.map = self.mapView;
    
    if (animate) self.selectedLocationMarker.appearAnimation = kGMSMarkerAnimationPop;
}

- (NSString*)displayStringForLocation:(GeocodingAddress*)location {
    NSMutableArray *locationStringComponents = [NSMutableArray new];
    if (location.locality.length) [locationStringComponents addObject:location.locality];
    if (location.administrativeAreaLevel1Short.length) [locationStringComponents addObject:location.administrativeAreaLevel1Short];
    else if (location.administrativeAreaLevel1.length) [locationStringComponents addObject:location.administrativeAreaLevel1];
    if (location.postalCode.length) [locationStringComponents addObject:location.postalCode];
    if (location.country.length) [locationStringComponents addObject:location.country];
    return [locationStringComponents componentsJoinedByString:@", "];
}

#pragma mark - Search display controller delegate

- (void)reloadAutocompleteResultsForSearchString:(NSString*)searchString {
    [self.autocompleteRequest cancelRequest];
    self.autocompleteRequest = [GeocodingRequestAutocomplete autocompleteGeocodingRequestWithInputString:searchString];
    
    [self.autocompleteRequest executeRequestWithCompletionHandler:^(NSArray *predictions, NSError *error) {
        self.autocompletePredictions = predictions;
        self.autocompleteRequest = nil;
        [self.searchDisplayController.searchResultsTableView reloadData];
    }];
    
    self.autocompleteReloadResultsDate = [NSDate date];
}

- (BOOL)searchDisplayController:(UISearchDisplayController*)controller shouldReloadTableForSearchString:(NSString*)searchString {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadAutocompleteResultsForSearchString:) object:self.autocompleteSearchString];
    [self performSelector:@selector(reloadAutocompleteResultsForSearchString:) withObject:searchString afterDelay:LocationSetup_Autocomplete_ReloadResultsTimeInterval];
    
    self.autocompleteSearchString = searchString;
    
    return NO;
}

#pragma mark - Table view datasource

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return self.autocompletePredictions.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *AutocompletePredictionCellIdentifier = @"AutocompletePredictionCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AutocompletePredictionCellIdentifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AutocompletePredictionCellIdentifier];
    
    GeocodingAutocompletePrediction *prediction = self.autocompletePredictions[indexPath.row];
    
    NSMutableAttributedString *placeDescription = [[NSMutableAttributedString alloc] initWithString:prediction.placeDescription attributes:nil];
    [placeDescription addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:17.0] range:NSMakeRange(0, prediction.placeDescription.length)];
    
    for (NSValue *matchedRangeValue in prediction.matchedRanges) {
        NSRange matchedRange = matchedRangeValue.rangeValue;
        [placeDescription addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0] range:matchedRange];
    }
    
    cell.textLabel.attributedText = placeDescription;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (IBAction)onNext:(id)sender {
    
}

@end
