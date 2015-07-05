#import "../Functions.h"

%hook PLCameraView

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
	PLCameraController *cont = [%c(PLCameraController) sharedInstance];
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
	PLCameraController *cont = [%c(PLCameraController) sharedInstance];
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

%hook PLCameraController

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

%ctor
{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, CFSTR("com.PS.CamRotate.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CamRotateLoader();
	if (CamRotateisOn) {
		dlopen("/System/Library/PrivateFrameworks/PhotoLibrary.framework/PhotoLibrary", RTLD_LAZY);
		%init;
	}
}
