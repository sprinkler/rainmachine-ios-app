#import "Constants.h"

//NSString *const TestServerURL = @"http://10.1.10.74";
//NSString *const TestServerURL = @"https://50.150.118.132";
//NSString *const TestServerURL = @"https://24.4.218.168"; // 3.55
NSString *const TestServerURL = @"https://ns.tremend.ro";
//NSString *const TestServerPort = @"443";
NSString *const TestServerPort = @"2443"; // 3.59
//NSString *const TestServerPort = @"65076";

NSString *const kGoogleMapsAPIKey = @"AIzaSyBmibJFgRN24DBK24m96jR3MgjwpIK9TeE";
NSString *const kGooglePlacesAPIServerKey = @"AIzaSyCKT3TO8ALbcSVtwVjlN8z6NVgvjuti8T0";

NSString *const kSprinklerAPIKey = @"ad03a0334376fadc5679e18e3f8a90b2";

NSString *const kDebugNewAPIVersion = @"DebugNewAPIVersion";
NSString *const kDebugLocalDevicesDiscoveryInterval = @"DebugLocalDevicesDiscoveryInterval";
NSString *const kDebugCloudDevicesDiscoveryInterval = @"DebugCloudDevicesDiscoveryInterval";
NSString *const kDebugDeviceGreyOutRetryCount = @"DebugDeviceGreyOutRetryCount";

NSString *const kCloudProxyFinderURLKey = @"CloudProxyFinderURLKey";
NSString *const kCloudProxyFinderStagingURL = @"https://proxy-finder.rainmachine.com:9000";
NSString *const kCloudProxyFinderURL = @"https://dev.proxy-finder.rainmachine.com:9000";
NSString *const kCloudProxyFinderStagingName = @"Staging";
NSString *const kCloudProxyFinderName = @"Dev";

NSString *const kCloudEmailValidatorURLKey = @"CloudEmailValidatorURLKey";
NSString *const kCloudEmailValidatorStagingURL = @"https://validator.rainmachine.com:8997";
NSString *const kCloudEmailValidatorURL = @"https://dev.validator.rainmachine.com:8010";

NSString* const kSprinklerKeychain_CookieDictionaryStorageKey = @"SprinklerKeychain_CookieDictionaryStorageKey";
NSString* const kSprinklerKeychain_CookiesKey = @"SprinklerKeychain_CookiesKey";
NSString* const kSprinklerKeychain_isSessionOnly = @"SprinklerKeychain_isSessionOnly";

NSString* const kSprinklerKeychain_CloudAccount = @"kSprinklerKeychain_CloudAccount";

NSString *const kSprinklerUserDefaults_AccessTokensDictionaryKey = @"kSprinklerUserDefaults_AccessTokensDictionaryKey";

NSString *const kNewSprinklerSelected = @"NewSprinklerSelected";
NSString *const kFirmwareUpdateNeeded = @"FirmwareUpdateNeeded";
NSString *const kSprinklerNetworkError = @"SprinklerNetworkError";
NSString *const kLoggedOutDetectedNotification = @"kLoggedOutDetectedNotification";
NSString *const kDeviceNotSupported = @"kDeviceNotSupported";

NSString *const kShowSettingsZones = @"kShowSettingsZones";
NSString *const kDashboardDisabledGraphIdentifiers = @"kDashboardDisabledGraphIdentifiers";

NSString *kVegetationTypeAPI4[] = {
    @"",
    @"Other",
    @"Lawn",
    @"Fruit trees",
    @"Flowers",
    @"Vegetables",
    @"Citrus",
    @"Trees & bushes",
    @"Other"
};

NSString *kVegetationType[] = {
    @"",
    @"",
    @"Lawn",
    @"Fruit trees",
    @"Flowers",
    @"Vegetables",
    @"Citrus",
    @"Trees & bushes",
    @"Other"
};

float kButtonInactiveOpacity = 0.51;

CGFloat kSprinklerBlueColor[3] = {0x33/255.0, 0x99/255.0, 0xcc/255.0};
CGFloat kWateringGreenButtonColor[3] = {0x33/255.0, 0x99/255.0, 0xcc/255.0};
CGFloat kWateringOrangeButtonColor[3] = {0xff/255.0, 0x99/255.0, 0x00/255.0};
CGFloat kWateringRedButtonColor[3] = {0xff/255.0, 0x44/255.0, 0x44/255.0};
CGFloat kMasterValveOrangeColor[3] = {253/255.0, 136/255.0, 36/255.0};
CGFloat kWaterImageStrokeColor[3] = {56 / 255.0, 136 / 255.0, 194 / 255.0};
CGFloat kWaterImageFillColor[3] = {107 / 255.0, 168 / 255.0, 207 / 255.0};
CGFloat kButtonBlueTintColor[3] = {21.0/255, 122.0/255, 251.0/255};

NSString *const kCustomRMFontName = @"rainmachine";

int const kLocalDevicesDiscoveryInterval = 6;
int const kLocalDevicesDiscoveryInterval_UserStarted = 3;
int const kCloudDevicesDiscoveryInterval = 15;
int const kDeviceGreyOutRetryCount = 3;

int const kMaxCounterValue = 300 * 60; // In seconds
int const kSprinklerUpdateCheckInterval = 24 * 60 * 60;
int const kUpdateProcessTimeoutInterval = 5 * 60;
int const kWheatherValueFontSize = 13;
int const kWheatherValueCustomFontSize = (kWheatherValueFontSize * 2);
int const kXCorrectionbetweenCustomAndNormalWheatherFont = (-6 * kWheatherValueCustomFontSize) / 30 + 1;
//int const kYCorrectionbetweenCustomNormalWheatherFont = (-10 * kWheatherValueCustomFontSize) / kWheatherValueFontSize;

int const kWizard_TimeoutWifiJoin = 200; // Usually the device restarts in a little bit more than 2 minutes
int const kCloudSettings_PollTimeInterval = 5;

NSString *daysOfTheWeek[7] = {@"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday", @"Sunday"};
NSString *monthsOfYear[12] = {@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December"};
NSString *abbrevMonthsOfYear[12] = {@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"June", @"July", @"Aug", @"Sept", @"Oct", @"Nov", @"Dec"};
NSString *abbrevWeekdays[7] = {@"Mon", @"Tue", @"Wed", @"Thu", @"Fri", @"Sat", @"Sun"};

// ---- Custom font glyphs ----

const unsigned short icon_blizzard = 0xe600;
const unsigned short icon_cold = 0xe601;
const unsigned short icon_du = 0xe602;
const unsigned short icon_few = 0xe603;
const unsigned short icon_fg = 0xe604;
const unsigned short icon_frza = 0xe605;
const unsigned short icon_fu = 0xe606;
const unsigned short icon_hot = 0xe607;
const unsigned short icon_ip = 0xe608;
const unsigned short icon_mist = 0xe609;
const unsigned short icon_mix = 0xe60a;
const unsigned short icon_na = 0xe60b;
const unsigned short icon_nbkn = 0xe60c;
const unsigned short icon_ndu = 0xe60d;
const unsigned short icon_nrasn = 0xe60e;
const unsigned short icon_nsct = 0xe60f;
const unsigned short icon_nskc = 0xe610;
const unsigned short icon_nsn = 0xe611;
const unsigned short icon_nsvrtsra = 0xe612;
const unsigned short icon_ntsra = 0xe613;
const unsigned short icon_nwind = 0xe614;
const unsigned short icon_sct = 0xe615;
const unsigned short icon_shra = 0xe616;
const unsigned short icon_skc = 0xe617;
const unsigned short icon_smoke = 0xe618;
const unsigned short icon_sn = 0xe619;
const unsigned short icon_tsra = 0xe61a;
const unsigned short icon_wind = 0xe61b;
const unsigned short icon_bkn = 0xe61c;
const unsigned short icon_fzrara = 0xe61d;
const unsigned short icon_hi_nshwrs = 0xe61e;
const unsigned short icon_hi_ntsra = 0xe61f;
const unsigned short icon_hi_shwrs = 0xe620;
const unsigned short icon_nfew = 0xe621;
const unsigned short icon_nfg = 0xe622;
const unsigned short icon_nmix = 0xe623;
const unsigned short icon_novc = 0xe624;
const unsigned short icon_ovc = 0xe625;
const unsigned short icon_ra = 0xe626;
const unsigned short icon_ra1 = 0xe627;
const unsigned short icon_raip = 0xe628;
const unsigned short icon_rasn = 0xe629;
const unsigned short icon_nra = 0xe62a;
const unsigned short icon_hi_tsra = 0xe62b;
const unsigned short icon_Stropitoare_Icon = 0xe62c;
const unsigned short icon_Stats_Icon = 0xe62d;
const unsigned short icon_Settings_Icon = 0xe62e;
const unsigned short icon_Devices_Icon = 0xe62f;
const unsigned short icon_Plus = 0xe630;
const unsigned short icon_Minus = 0xe631;
const unsigned short icon_Add = 0xe632;
