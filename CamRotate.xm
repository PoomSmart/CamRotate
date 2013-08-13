#import <Foundation/Foundation.h>

static BOOL isiOS5 = (kCFCoreFoundationVersionNumber >= 675.00 && kCFCoreFoundationVersionNumber < 793.00);
static BOOL CamRotateisOn;
static BOOL CamRotateLock;
static BOOL SyncOrientation;

static int rotationStyle;
static int orientationValue;

static void CamRotateLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.CamRotate.plist"];
	id CamRotateEnabled = [dict objectForKey:@"CamRotateEnabled"];
	CamRotateisOn = CamRotateEnabled ? [CamRotateEnabled boolValue] : NO;
	id CamRotateLockEnabled = [dict objectForKey:@"CamRotateLock"];
	CamRotateLock = CamRotateLockEnabled ? [CamRotateLockEnabled boolValue] : NO;
	id SyncOrientationEnabled = [dict objectForKey:@"SyncOrientation"];
	SyncOrientation = SyncOrientationEnabled ? [SyncOrientationEnabled boolValue] : NO;
	id RotationStyle = [dict objectForKey:@"RotationStyle"];
	rotationStyle = RotationStyle ? [RotationStyle integerValue] : 2;
	id OrientationValue = [dict objectForKey:@"OrientationValue"];
	orientationValue = OrientationValue ? [OrientationValue integerValue] : 1;
}

%hook PLCameraView

- (int)rotationStyle
{
	return CamRotateisOn && !isiOS5 ? rotationStyle : %orig;
}

- (void)setRotationStyle:(int)style
{
	if (CamRotateisOn && !isiOS5)
		%orig(rotationStyle);
	else %orig;
}

- (int)_glyphOrientationForCameraOrientation:(int)arg1
{
	if (CamRotateisOn) {
		if (CamRotateLock) return orientationValue;
		if (SyncOrientation) {
			UIInterfaceOrientation orientation = [[UIDevice currentDevice] orientation];
			switch (orientation) {
				case UIInterfaceOrientationPortrait:
					return 1; break;
				case UIInterfaceOrientationPortraitUpsideDown:
					return 2; break;
				case UIInterfaceOrientationLandscapeLeft:
					return 4; break;
				case UIInterfaceOrientationLandscapeRight:
					return 3; break;
			}
		}
	}
	return %orig;
}

%end


static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	CamRotateLoader();
}

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, CFSTR("com.PS.CamRotate.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CamRotateLoader();
  	%init;
  	[pool release];
}
