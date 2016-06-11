#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <Cephei/HBListController.h>
#import <Cephei/HBAppearanceSettings.h>
#import "Common.h"
#import "../PS.h"
#import "../PSPrefs.x"
#import <dlfcn.h>

@interface CamRotatePreferenceController : HBListController
@end

@implementation CamRotatePreferenceController

HavePrefs()

+ (nullable NSString *)hb_specifierPlist
{
	return @"CamRotate";
}

- (void)masterSwitch:(id)value specifier:(PSSpecifier *)spec
{
	[self setPreferenceValue:value specifier:spec];
	system("killall Camera");
}

- (void)loadView
{
	[super loadView];
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
	UILabel *tweakLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 16, 320, 50)];
	tweakLabel.text = @"CamRotate";
	tweakLabel.textColor = isiOS7Up ? UIColor.systemGreenColor : UIColor.greenColor;
	tweakLabel.backgroundColor = UIColor.clearColor;
	tweakLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:50.0];
	tweakLabel.textAlignment = 1;
	tweakLabel.autoresizingMask = 0x12;
	[headerView addSubview:tweakLabel];
	[tweakLabel release];
	UILabel *des = [[UILabel alloc] initWithFrame:CGRectMake(0, 75, 320, 14)];
	des.text = @"Rotate camera interface in styles";
	des.backgroundColor = UIColor.clearColor;
	des.alpha = 0.8;
	des.font = [UIFont systemFontOfSize:14.0];
	des.textAlignment = 1;
	des.autoresizingMask = 0xa;
	[headerView addSubview:des];
	[des release];
	self.table.tableHeaderView = headerView;
	[headerView release];
}

- (instancetype)init
{
	if (self == [super init]) {
		HBAppearanceSettings *appearanceSettings = [[HBAppearanceSettings alloc] init];
		appearanceSettings.tintColor = isiOS7Up ? UIColor.systemGreenColor : UIColor.greenColor;
		appearanceSettings.tableViewCellTextColor = isiOS7Up ? UIColor.systemGreenColor : UIColor.greenColor;
		self.hb_appearanceSettings = appearanceSettings;
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"💚" style:UIBarButtonItemStylePlain target:self action:@selector(love)] autorelease];
	}
	return self;
}

- (void)love
{
	SLComposeViewController *twitter = [[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter] retain];
	twitter.initialText = @"#CamRotate by @PoomSmart is really awesome!";
	[self.navigationController presentViewController:twitter animated:YES completion:nil];
	[twitter release];
}

@end

__attribute__((constructor)) static void ctor()
{
	if (isiOS56)
		dlopen("/Library/Application Support/CamRotate/Workaround_Cephei_iOS56.dylib", RTLD_LAZY);
}