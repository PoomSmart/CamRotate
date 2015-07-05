#import "../Functions.h"

%hook PLApplicationCameraViewController

- (void)loadView
{
	%orig;
	if (rotationStyle == 3) {
		PLCameraView *view = MSHookIvar<PLCameraView *>(self, "_cameraView");
		MSHookIvar<NSInteger>(view, "_rotationStyle") = -1;
	}
}

%end

%hook PLUICameraViewController

- (void)viewWillAppear:(BOOL)appear
{
	%orig;
	if (rotationStyle == 3) {
		PLCameraView *view = [self _cameraView];
		MSHookIvar<NSInteger>(view, "_rotationStyle") = -1;
	}
}

%end

%hook PLCameraView

- (NSInteger)_glyphOrientationForCameraOrientation:(NSInteger)orientation
{
	return glyphOrientationOverride(orientation, %orig);
}

- (CGFloat)previewImageRotationAngle
{
	if (rotationStyle == 3)
		MSHookIvar<NSInteger>(self, "_rotationStyle") = 2;
	return %orig;
}

- (void)_setupAnimatePreviewDown:(id)down flipImage:(BOOL)image panoImage:(BOOL)image3 snapshotFrame:(CGRect)frame
{
	%orig;
	if (rotationStyle == 3)
		MSHookIvar<NSInteger>(self, "_rotationStyle") = -1;
}

%end

%hook PLCameraElapsedTimeView

- (void)_setDeviceOrientation:(NSInteger)orientation animated:(BOOL)animated
{
	if (unlockVideo)
		return;
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

- (void)accelerometer:(id)accelerometer didChangeDeviceOrientation:(NSInteger)orientation
{
	unlockVideo = [self isCapturingVideo] && UnlockVideoUI;
	%orig;
	unlockVideo = NO;
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
