#import "../Functions.h"

%hook CMKCaptureController

%new
- (BOOL)isSyncOrientation
{
	return SyncOrientation;
}

- (BOOL)isCapturingVideo
{
	return UnlockVideoUI && unlockVideo ? NO : %orig;
}

%end

%hook CMKCameraView

- (NSInteger)_glyphOrientationForCameraOrientation:(NSInteger)orientation
{
	return glyphOrientationOverride(orientation, %orig);
}

- (void)_updateEnabledControlsWithReason:(id)reason forceLog:(BOOL)log
{
	%orig;
	if (CamRotateLock)
		[self _rotateCameraControlsAndInterface];
}

- (void)_cameraOrientationChanged:(NSInteger)orientation
{
	CMKCaptureController *cont = [%c(CMKCaptureController) sharedInstance];
	unlockVideo = [cont isCapturingVideo] && UnlockVideoUI;
	%orig;
	unlockVideo = NO;
}

- (BOOL)_shouldApplyRotationDirectlyToTopBarForOrientation:(NSInteger)orientation cameraMode:(NSInteger)mode
{
	return rotationStyle == 4 ? YES : %orig;
}

- (void)_updateTopBarStyleForDeviceOrientation:(NSInteger)orientation
{
	CMKCaptureController *cont = [%c(CMKCaptureController) sharedInstance];
	if (cont) {
		unlockVideo = UnlockVideoUI;
		NSInteger origMode = MSHookIvar<NSInteger>(cont, "_cameraMode");
		if (rotationStyle == 4)
			MSHookIvar<NSInteger>(cont, "_cameraMode") = 1;
		%orig;
		MSHookIvar<NSInteger>(cont, "_cameraMode") = origMode;
		unlockVideo = NO;
	} else
		%orig;
}

%end

%ctor
{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, CFSTR("com.PS.CamRotate.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CamRotateLoader();
	if (CamRotateisOn) {
		dlopen("/System/Library/PrivateFrameworks/CameraKit.framework/CameraKit", RTLD_LAZY);
		%init;
	}
}
