#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <Cephei/HBListController.h>
#import <Cephei/HBAppearanceSettings.h>
#import "Common.h"
#import "../PS.h"
#import "../PSPrefs.x"

@interface CamRotatePreferenceController : HBListController
@end

@implementation CamRotatePreferenceController

HavePrefs()

+ (NSString *)hb_specifierPlist
{
	return @"CamRotate";
}

- (void)masterSwitch:(id)value specifier:(PSSpecifier *)spec
{
	[self setPreferenceValue:value specifier:spec];
	system("killall Camera");
}

HaveBanner2(@"CamRotate", isiOS7Up ? UIColor.systemGreenColor : UIColor.greenColor, @"Rotate camera interface in styles", UIColor.greenColor)

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