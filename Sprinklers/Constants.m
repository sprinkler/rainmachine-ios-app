#import "Constants.h"

//NSString *const TestServerURL = @"http://10.1.10.74";
//NSString *const TestServerURL = @"https://50.150.118.132";
//NSString *const TestServerURL = @"https://24.4.218.168"; // 3.55
NSString *const TestServerURL = @"https://ns.tremend.ro";
//NSString *const TestServerPort = @"443";
NSString *const TestServerPort = @"2443"; // 3.59
//NSString *const TestServerPort = @"65076";

NSString *const kNewCurrentSprinklerSelected = @"NewCurrentSprinklerSelected";
NSString *const kFirmwareUpdateNeeded = @"FirmwareUpdateNeeded";

float kLoginGreenButtonColor[3] = {2.0/255, 214.0/255, 100.0/255};
float kWateringGreenButtonColor[3] = {0.0/255, 162.0/255, 0.0/255};
float kWateringOrangeButtonColor[3] = {255.0/255, 162.0/255, 0.0/255};
float kWateringRedButtonColor[3] = {255.0/255, 0.0/255, 0.0/255};
float kWindowTintColorOnBlueNavBar[3] = {146.0/255, 146.0/255, 146.0/255};

float kWaterImageStrokeColor[3] = {56 / 255.0, 136 / 255.0, 194 / 255.0};
float kWaterImageFillColor[3] = {107 / 255.0, 168 / 255.0, 207 / 255.0};
float kBarBlueColor[3] = {1 / 255.0, 152 / 255.0, 208 / 255.0};

NSString *const kCustomRMFontName = @"rainmachine";

int const kMaxCounterValue = 300 * 60; // In seconds
int const kSprinklerUpdateCheckInterval = 24 * 60 * 60;
int const kUpdateProcessTimeoutInterval = 5 * 60;

NSString *daysOfTheWeek[7] = {@"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday", @"Sunday"};

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
const unsigned short icon_Up = 0xe630;
const unsigned short icon_Down = 0xe631;
const unsigned short icon_Plus = 0xe632;
const unsigned short icon_Minus = 0xe633;
