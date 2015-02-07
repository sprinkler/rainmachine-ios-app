#define ENABLE_DEBUG_SETTINGS YES

#define broadcastPort   15800
#define listenPort      15900

#define listenTimeout   10.0
#define refreshTimeout  20.0

#define resendTimeout   1.0
#define keepAliveTime   0.05

#define burstBroadcasts 1
#define keepAliveTo     50

#define messageDelimiter    @"||"
#define keepAliveURL        @"www.sprinklers.ro"
#define keepAlivePort       16000
#define keepAliveTimeout    0

extern NSString *const kGoogleMapsAPIKey;
extern NSString *const kGooglePlacesAPIServerKey;

extern NSString *const kDebugNewAPIVersion;
extern NSString *const kDebugLocalDevicesDiscoveryInterval;
extern NSString *const kDebugCloudDevicesDiscoveryInterval;
extern NSString *const kDebugDeviceGreyOutRetryCount;

extern NSString* const TestServerURL;
extern NSString* const TestServerPort;
extern NSString* const kCloudProxyFinderURLKey;
extern NSString *const kCloudProxyFinderStagingURL;
extern NSString *const kCloudProxyFinderURL;

extern NSString* const kSprinklerKeychain_CookieDictionaryStorageKey;
extern NSString* const kSprinklerKeychain_CookiesKey;
extern NSString* const kSprinklerKeychain_isSessionOnly;

extern NSString* const kSprinklerKeychain_CloudAccount;

extern NSString* const kSprinklerUserDefaults_AccessTokensDictionaryKey;

extern NSString* const kNewSprinklerSelected;
extern NSString *const kFirmwareUpdateNeeded;
extern NSString *const kSprinklerNetworkError;
extern NSString *const kLoggedOutDetectedNotification;
extern NSString *const kDeviceNotSupported;

extern NSString *const kShowSettingsZones;

NSString *kVegetationType[9];
NSString *kVegetationTypeAPI4[9];

extern float kButtonInactiveOpacity;

extern CGFloat kSprinklerBlueColor[3];
extern CGFloat kWateringGreenButtonColor[3];
extern CGFloat kWateringOrangeButtonColor[3];
extern CGFloat kMasterValveOrangeColor[3];
extern CGFloat kWateringRedButtonColor[3];
extern CGFloat kWaterImageFillColor[3];
extern CGFloat kWaterImageStrokeColor[3];
extern CGFloat kButtonBlueTintColor[3];

extern NSString* const kCustomRMFontName;

extern int const kLocalDevicesDiscoveryInterval_UserStarted;
extern int const kLocalDevicesDiscoveryInterval;
extern int const kCloudDevicesDiscoveryInterval;
extern int const kDeviceGreyOutRetryCount;

extern int const kSprinklerUpdateCheckInterval;
extern int const kMaxCounterValue;
extern int const kUpdateProcessTimeoutInterval;
extern int const kWheatherValueFontSize;
extern int const kWheatherValueCustomFontSize;
extern int const kXCorrectionbetweenCustomAndNormalWheatherFont;

extern int const kWizard_TimeoutWifiJoin;

extern NSString *daysOfTheWeek[7];
extern NSString *monthsOfYear[12];
extern NSString *abbrevMonthsOfYear[12];

#define kAlertView_LoggedOut 1
#define kAlertView_Error 2
#define kAlertView_UpdateNow 3
#define kAlertView_InvalidProgram 4
#define kAlertView_UnsavedChanges 5
#define kAlertView_Timeout 6
#define kAlertView_Finished 7
#define kAlertView_ResumeRainDelay 8
#define kAlertView_NoActiveZones 9
#define kAlertView_DeviceNotSupported 10
#define kAlertView_ApiVerConnectionError 11
#define kAlertView_SetupWizard_CannotStart 12
#define kAlertView_SetupWizard_WifiJoinTimedOut 13
#define kAlertView_SetupWizard_CannotContinueWizard 14
#define kAlertView_SetupWizard_ReconnectedToSprinkler 15
#define kAlertView_SetupWizard_NoLocationWithContinueMessage 16
#define kAlertView_SetupWizard_NoLocationWithoutContinueMessage 17

#define  kOneDayInSeconds (24 * 60 * 60)

#define kRainDelayRefreshTimeInterval 30 // Value is specified in seconds
#define kWaterNowRefreshTimeInterval 10 // Value is specified in seconds
#define kWaterNowRefreshTimeInterval_AfterUserAction 3 // Value is specified in seconds
#define kWaterNowMaxRefreshInterval (kWaterNowRefreshTimeInterval * 4)

// ---- Custom font glyphs ----

extern const unsigned short icon_blizzard;
extern const unsigned short icon_cold;
extern const unsigned short icon_du;
extern const unsigned short icon_few;
extern const unsigned short icon_fg;
extern const unsigned short icon_frza;
extern const unsigned short icon_fu;
extern const unsigned short icon_hot;
extern const unsigned short icon_ip;
extern const unsigned short icon_mist;
extern const unsigned short icon_mix;
extern const unsigned short icon_na;
extern const unsigned short icon_nbkn;
extern const unsigned short icon_ndu;
extern const unsigned short icon_nrasn;
extern const unsigned short icon_nsct;
extern const unsigned short icon_nskc;
extern const unsigned short icon_nsn;
extern const unsigned short icon_nsvrtsra;
extern const unsigned short icon_ntsra;
extern const unsigned short icon_nwind;
extern const unsigned short icon_sct;
extern const unsigned short icon_shra;
extern const unsigned short icon_skc;
extern const unsigned short icon_smoke;
extern const unsigned short icon_sn;
extern const unsigned short icon_tsra;
extern const unsigned short icon_wind;
extern const unsigned short icon_bkn;
extern const unsigned short icon_fzrara;
extern const unsigned short icon_hi_nshwrs;
extern const unsigned short icon_hi_ntsra;
extern const unsigned short icon_hi_shwrs;
extern const unsigned short icon_nfew;
extern const unsigned short icon_nfg;
extern const unsigned short icon_nmix;
extern const unsigned short icon_novc;
extern const unsigned short icon_ovc;
extern const unsigned short icon_ra;
extern const unsigned short icon_ra1;
extern const unsigned short icon_raip;
extern const unsigned short icon_rasn;
extern const unsigned short icon_nra;
extern const unsigned short icon_hi_tsra;
extern const unsigned short icon_Stropitoare_Icon;
extern const unsigned short icon_Stats_Icon;
extern const unsigned short icon_Settings_Icon;
extern const unsigned short icon_Devices_Icon;
extern const unsigned short icon_Plus;
extern const unsigned short icon_Minus;
extern const unsigned short icon_Add;
