//
//  LocationSetupVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProvisionLocationSetupVC.h"
#import "ColoredBackgroundButton.h"
#import "Constants.h"
#import "Additions.h"
#import "GoogleElevation.h"
#import "GoogleTimezone.h"
#import "GoogleAutocompletePrediction.h"
#import "GoogleRequest.h"
#import "GoogleRequestReverseGeocoding.h"
#import "GoogleRequestAutocomplete.h"
#import "GoogleRequestPlaceDetails.h"
#import "GoogleRequestElevation.h"
#import "GoogleRequestTimezone.h"
#import "MBProgressHUD.h"
#import <CoreLocation/CoreLocation.h>
#import "ServerProxy.h"
#import "NetworkUtilities.h"
#import "ProvisionDateAndTimeManualVC.h"

const double LocationSetup_MapView_InitializeTimeout                = 3.0;
const double LocationSetup_MapView_StartRegionSizeMeters            = 1000.0;
const double LocationSetup_Autocomplete_ReloadResultsTimeInterval   = 0.3;

#pragma mark -

@interface ProvisionLocationSetupVC ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSDate *autocompleteReloadResultsDate;
@property (nonatomic, strong) NSString *autocompleteSearchString;
@property (nonatomic, strong) NSArray *autocompletePredictions;
@property (nonatomic, strong) GoogleRequestAutocomplete *autocompleteRequest;
@property (nonatomic, assign) BOOL skipped;

- (BOOL)initializeLocationServices;
- (void)displayLocationServicesDisabledAlert;
- (void)moveCameraToLocation:(CLLocation*)location animated:(BOOL)animate;

@property (nonatomic, assign) BOOL startLocationFound;
@property (nonatomic, strong) GoogleTimezone *selectedLocationTimezone;
@property (nonatomic, strong) GoogleElevation *selectedLocationElevation;
@property (nonatomic, strong) GMSMarker *selectedLocationMarker;

- (void)markSelectedLocationAnimated:(BOOL)animate;
- (NSString*)displayStringForLocation:(GoogleAddress*)location;
- (void)updateLocationSearchBar;

@property (strong, nonatomic) ServerProxy *provisionServerProxy;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (weak, nonatomic) IBOutlet ColoredBackgroundButton *saveButton;

@end

#pragma mark -

@implementation ProvisionLocationSetupVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;
    
    self.title = @"Select your location";
    self.skipped = NO;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) self.edgesForExtendedLayout = UIRectEdgeNone;
    
    if (self.isPartOfWizard) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next"
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(onSkipLocation:)];
    }
    
    [self.saveButton setCustomBackgroundColorFromComponents:kSprinklerBlueColor];
    [self.saveButton setTitle:@"Save" forState:UIControlStateNormal];
    
    self.mapView.superview.backgroundColor = [UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1];
    
    if (![self initializeLocationServices]) {
        [self displayLocationServicesDisabledAlert];
        return;
    }
    
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = YES;
    self.mapView.settings.myLocationButton = YES;
    
    [self showHud];
    [self performSelector:@selector(hideHud) withObject:nil afterDelay:LocationSetup_MapView_InitializeTimeout];

    [self setWizardNavBarForVC:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)applicationWillEnterForeground:(id)notif
{
    self.mapView.myLocationEnabled = NO;
    self.mapView.myLocationEnabled = YES;

    self.mapView.settings.myLocationButton = NO;
    self.mapView.settings.myLocationButton = YES;
    
    self.mapView.mapType = kGMSTypeNone;
    self.mapView.mapType = kGMSTypeNormal;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.startLocationFound) {
        [self.mapView addObserver:self forKeyPath:@"myLocation" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    }
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
        
        [self moveCameraToLocation:self.mapView.myLocation animated:YES];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideHud) object:nil];
        [[GoogleRequestReverseGeocoding reverseGeocodingRequestWithLocation:self.mapView.myLocation] executeRequestWithCompletionHandler:^(GoogleAddress *result, NSError *error) {
            if (error) {
                [self hideHud];
                return;
            }

            self.selectedLocationAddress = result;
            [self updateLocationSearchBar];
            [self markSelectedLocationAnimated:YES];
            
            [[GoogleRequestElevation elevationRequestWithLocation:self.selectedLocationAddress.location] executeRequestWithCompletionHandler:^(GoogleElevation *result, NSError *error) {
                self.selectedLocationElevation = result;
                [[GoogleRequestTimezone timezoneRequestWithLocation:self.selectedLocationAddress.location] executeRequestWithCompletionHandler:^(GoogleTimezone *result, NSError *error) {
                    self.selectedLocationTimezone = result;
                    [self hideHud];
                }];
            }];
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
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    
    [self enableMyLocation];
    
    return YES;
}

- (void)enableMyLocation
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        [self displayLocationServicesDisabledAlert];
    }
    
    if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
        if (status == kCLAuthorizationStatusNotDetermined) {
            [self.locationManager requestWhenInUseAuthorization];
        } else {
            // iOS 8 - this asks user for location permission
            [self.locationManager startUpdatingLocation];
        }
    } else {
        if (status != kCLAuthorizationStatusDenied) {
            // iOS 7 - this asks user for location permission
            [self.locationManager startUpdatingLocation];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status != kCLAuthorizationStatusNotDetermined) {
        [self performSelectorOnMainThread:@selector(enableMyLocation) withObject:nil waitUntilDone:[NSThread isMainThread]];
    }
}

- (void)displayLocationServicesDisabledAlert {
    if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Location Services disabled"
                                                                                 message:@"Allow RainMachine to access your location in your phone's settings."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [alertController.view setTintColor:[UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1]];
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

- (void)displayNoLocationAlertWithContinueMessage:(BOOL)continueMessage skip:(BOOL)skip {
    NSString *titleMessage = skip ? @"Skip location setup" : @"Location couldn't be retrieved";
    NSString *bodyMessage = skip ? @"Do you really want to skip location setup?" : @"Do you want to enter the location manually?";
    NSString *cancelMessage = continueMessage ? @"No, continue setup" : @"Cancel";
    if (skip) {
        cancelMessage = @"Cancel";
    }
    NSString *okTitle = skip ? @"Skip" : @"Enter location";
    if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:titleMessage
                                                                                 message:bodyMessage
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:cancelMessage style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            if (skip) {
                // Cancel
            } else {
                if (continueMessage) {
                    [self continueSetup];
                }
            }
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (skip) {
                self.skipped = YES;
                [self continueSetup];
            } else {
                [self.locationSearchBar becomeFirstResponder];
            }
        }]];
        [alertController.view setTintColor:[UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:titleMessage
                                                            message:bodyMessage
                                                           delegate:self
                                                  cancelButtonTitle:cancelMessage
                                                  otherButtonTitles:okTitle, nil];
        alertView.tag = continueMessage ? kAlertView_SetupWizard_NoLocationWithContinueMessage : kAlertView_SetupWizard_NoLocationWithoutContinueMessage;
        if (skip) {
            alertView.tag = kAlertView_SetupWizard_SkipLocationSetup;
        }
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [super alertView:theAlertView didDismissWithButtonIndex:buttonIndex];
    
    // This is the no location alert view
    if (buttonIndex != theAlertView.cancelButtonIndex) {
        if (theAlertView.tag == kAlertView_SetupWizard_SkipLocationSetup) {
            [self continueSetup];
        } else {
            if ((theAlertView.tag == kAlertView_SetupWizard_NoLocationWithContinueMessage) ||
                (theAlertView.tag == kAlertView_SetupWizard_NoLocationWithoutContinueMessage)) {
                [self.locationSearchBar becomeFirstResponder];
            }
        }
    } else {
        if (theAlertView.tag == kAlertView_SetupWizard_NoLocationWithContinueMessage) {
            [self continueSetup];
        }
    }
    
    if (theAlertView.tag == kAlertView_SetupWizard_NewLocationSuccesfullySet) {
        if (self.isPartOfWizard) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)moveCameraToLocation:(CLLocation*)location animated:(BOOL)animate {
    float zoom = [GMSCameraPosition zoomAtCoordinate:location.coordinate
                                           forMeters:LocationSetup_MapView_StartRegionSizeMeters
                                           perPoints:self.mapView.bounds.size.width];
    
    GMSCameraPosition *cameraPosition = [GMSCameraPosition cameraWithLatitude:location.coordinate.latitude
                                                                    longitude:location.coordinate.longitude
                                                                         zoom:zoom];
    
    if (animate) [self.mapView animateToCameraPosition:cameraPosition];
    else self.mapView.camera = cameraPosition;
}

- (void)markSelectedLocationAnimated:(BOOL)animate {
    if (!self.selectedLocationAddress) return;
    
    self.selectedLocationMarker.map = nil;
    self.selectedLocationMarker = [GMSMarker markerWithPosition:self.selectedLocationAddress.location.coordinate];
    self.selectedLocationMarker.snippet = [self displayStringForLocation:self.selectedLocationAddress];
    self.selectedLocationMarker.map = self.mapView;
    self.mapView.selectedMarker = self.selectedLocationMarker;
    
    if (animate) self.selectedLocationMarker.appearAnimation = kGMSMarkerAnimationPop;
}

- (NSString*)displayStringForLocation:(GoogleAddress*)location {
    NSMutableArray *locationStringComponents = [NSMutableArray new];
    
    if (location.premise.length) [locationStringComponents addObject:location.premise];
    if (location.route.length && location.streetNumber.length) [locationStringComponents addObject:[NSString stringWithFormat:@"%@ %@",location.route,location.streetNumber]];
    else if (location.route.length) [locationStringComponents addObject:location.route];
    else if (location.streetNumber.length) [locationStringComponents addObject:location.streetNumber];
    
    if (location.locality.length && location.postalCode.length) [locationStringComponents addObject:[NSString stringWithFormat:@"%@ %@",location.locality,location.postalCode]];
    else if (location.locality.length) [locationStringComponents addObject:location.locality];
    else if (location.postalCode.length) [locationStringComponents addObject:location.postalCode];
    
    if (location.administrativeAreaLevel1Short.length) [locationStringComponents addObject:location.administrativeAreaLevel1Short];
    else if (location.administrativeAreaLevel1.length) [locationStringComponents addObject:location.administrativeAreaLevel1];
    
    if (location.country.length) [locationStringComponents addObject:location.country];
    
    return [locationStringComponents componentsJoinedByString:@", "];
}

- (void)updateLocationSearchBar {
    self.locationSearchBar.text = [self displayStringForLocation:self.selectedLocationAddress];
    self.locationSearchBar.placeholder = (self.locationSearchBar.text.length ? nil : @"Select your location");
}

#pragma mark - Search display controller delegate

- (void)reloadAutocompleteResultsForSearchString:(NSString*)searchString {
    [self.autocompleteRequest cancelRequest];
    self.autocompleteRequest = [GoogleRequestAutocomplete autocompleteRequestWithInputString:searchString];
    
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

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController*)controller {
    if ([controller respondsToSelector:@selector(searchBar:textDidChange:)]) {
        [(id<UISearchBarDelegate>)controller searchBar:controller.searchBar textDidChange:controller.searchBar.text];
    }
}

#pragma  mark - Search bar delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar*)searchBar {
    if (self.selectedLocationAddress) [self moveCameraToLocation:self.selectedLocationAddress.location animated:YES];
}

- (BOOL)searchBar:(UISearchBar*)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text {
    return self.searchDisplayController.isActive;
}

- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar {
    [self performSelector:@selector(updateLocationSearchBar) withObject:nil afterDelay:0.0];
}

#pragma mark - Table view datasource

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return self.autocompletePredictions.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *AutocompletePredictionCellIdentifier = @"AutocompletePredictionCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AutocompletePredictionCellIdentifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AutocompletePredictionCellIdentifier];
    
    GoogleAutocompletePrediction *prediction = self.autocompletePredictions[indexPath.row];
    
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
    [self.searchDisplayController setActive:NO animated:YES];
    
    GoogleAutocompletePrediction *prediction = self.autocompletePredictions[indexPath.row];
    
    [self showHud];
    [[GoogleRequestPlaceDetails placeDetailsRequestWithAutocompletePrediction:prediction] executeRequestWithCompletionHandler:^(GoogleAddress *result, NSError *error) {
        if (error) {
            [self hideHud];
            return;
        }
        
        self.selectedLocationAddress = result;
        [self updateLocationSearchBar];
        [self markSelectedLocationAnimated:YES];
        
        [self moveCameraToLocation:result.location animated:YES];
        
        [[GoogleRequestElevation elevationRequestWithLocation:self.selectedLocationAddress.location] executeRequestWithCompletionHandler:^(GoogleElevation *result, NSError *error) {
            self.selectedLocationElevation = result;
            [[GoogleRequestTimezone timezoneRequestWithLocation:self.selectedLocationAddress.location] executeRequestWithCompletionHandler:^(GoogleTimezone *result, NSError *error) {
                self.selectedLocationTimezone = result;
                [self hideHud];
            }];
        }];
    }];
}

#pragma mark - Actions

- (void)continueSetup
{
    if (!self.skipped) {
        CLLocation *location = [self detectedLocation];
        // self.selectedLocationAddress contains the selected location
        // self.selectedLocationElevation.elevation contains the elevation of the selected location
        // self.selectedLocationTimezone.timeZoneId contains the timezone of the selected location
        if (self.sprinkler) {
            self.provisionServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];
        } else {
            self.provisionServerProxy = [[ServerProxy alloc] initWithSprinkler:self.dbSprinkler delegate:self jsonRequest:YES];
        }
        
        [self.provisionServerProxy setLocation:location.coordinate.latitude
                                     longitude:location.coordinate.longitude
                                          name:(self.selectedLocationAddress ? [self displayStringForLocation:self.selectedLocationAddress] : nil)
                                      timezone:[[NSTimeZone localTimeZone] name]];
        
        [self showHud];
    } else {
        [self continueWithDateTime];
    }
}

- (IBAction)onSkipLocation:(id)sender {
    if (self.isPartOfWizard) {
        [self displayNoLocationAlertWithContinueMessage:YES skip:YES];
    }
}

- (IBAction)onSave:(id)sender {
    if ([self detectedLocation]) {
        [self continueSetup];
    } else {
        [self displayNoLocationAlertWithContinueMessage:YES skip:NO];
    }
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.provisionServerProxy) {
    }
    
    [self hideHud];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    
    if (serverProxy == self.provisionServerProxy) {
        //    TODO: handle error code
        [self hideHud];
        
        if (self.isPartOfWizard) {
            [self continueWithDateTime];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                                message:@"Your new location has been succesfully set."
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            alertView.tag = kAlertView_SetupWizard_NewLocationSuccesfullySet;
            [alertView show];
        }
    }
    
    [self hideHud];
}

- (void)loggedOut {
    
    [self hideHud];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"Authentication failed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)showHud {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.view.userInteractionEnabled = NO;
}

- (void)hideHud {
    self.hud = nil;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.view.userInteractionEnabled = YES;
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    [self displayNoLocationAlertWithContinueMessage:NO skip:NO];
}

- (void)continueWithDateTime
{
    ProvisionDateAndTimeManualVC *dateTimeVC = [[ProvisionDateAndTimeManualVC alloc] init];
    dateTimeVC.sprinkler = self.sprinkler;
//    dateTimeVC.delegate = self.delegate;
    dateTimeVC.locationSetupVC = self;
    
//    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:dateTimeVC];
//    [self.navigationController presentViewController:navVC animated:NO completion:nil];
    
    [self.navigationController pushViewController:dateTimeVC animated:YES];
}

- (CLLocation*)detectedLocation
{
    if (self.selectedLocationAddress) {
        return self.selectedLocationAddress.location;
    }
    
    return self.mapView.myLocation;
}

@end
