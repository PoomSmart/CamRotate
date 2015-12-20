#import "../Functions.h"

%hook CAMViewfinderViewController

- (BOOL)_shouldApplyTopBarRotationForMode:(int)mode device:(int)device
{
	return rotationStyle == 4 ? YES : %orig;
}

- (int)_autorotationStyle
{
	return rotationStyle == 3 ? 0 : %orig;
}

- (BOOL)_shouldRotateTopBarForMode:(int)mode device:(int)device
{
	return rotationStyle == 4 ? YES : %orig;
}

%end

%hook CAMMotionController

- (int)captureOrientation
{
	return glyphOrientationOverride(%orig);
}

%end

/*- (void)_updateTopBarStyleForDeviceOrientation:(int)orientation
{
	CMKCaptureController *cont = [%c(CMKCaptureController) sharedInstance];
	if (cont) {
		NSInteger origMode = MSHookIvar<NSInteger>(cont, "_cameraMode");
		if (rotationStyle == 4)
			MSHookIvar<NSInteger>(cont, "_cameraMode") = 1;
		%orig;
		MSHookIvar<NSInteger>(cont, "_cameraMode") = origMode;
	} else
		%orig;
}*/

%ctor
{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, CFSTR("com.PS.CamRotate.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CamRotateLoader();
	if (CamRotateisOn) {
		dlopen("/System/Library/PrivateFrameworks/CameraUI.framework/CameraUI", RTLD_LAZY);
		%init;
	}
}