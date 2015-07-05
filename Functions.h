#import <UIKit/UIKit.h>
#import "Header.h"

static BOOL CamRotateisOn;
static BOOL CamRotateLock;
static BOOL SyncOrientation;
static BOOL UnlockVideoUI;
static BOOL unlockVideo = NO;

static NSInteger rotationStyle;
static NSInteger orientationValue;

static void CamRotateLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	id val = dict[@"CamRotateEnabled"];
	CamRotateisOn = [val boolValue];
	val = dict[@"CamRotateLock"];
	CamRotateLock = [val boolValue];
	val = dict[@"SyncOrientation"];
	SyncOrientation = [val boolValue];
	val = dict[@"UnlockVideoUI"];
	UnlockVideoUI = [val boolValue];
	val = dict[@"RotationStyle"];
	rotationStyle = val ? [val integerValue] : 2;
	val = dict[@"OrientationValue"];
	orientationValue = val ? [val integerValue] : 1;
}

static NSInteger glyphOrientationOverride(NSInteger orientation, NSInteger orig)
{
	if (CamRotateLock)
		return orientationValue;
	if (SyncOrientation) {
		UIInterfaceOrientation orient = [[UIDevice currentDevice] orientation];
		switch (orient) {
			case UIInterfaceOrientationPortrait:
				return 1;
			case UIInterfaceOrientationPortraitUpsideDown:
				return 2;
			case UIInterfaceOrientationLandscapeLeft:
				return 4;
			case UIInterfaceOrientationLandscapeRight:
				return 3;
			default:
				return orig;
		}
	}
	return orig;
}

static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	CamRotateLoader();
}
