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
	CamRotateisOn = [dict[@"CamRotateEnabled"] boolValue];
	CamRotateLock = [dict[@"CamRotateLock"] boolValue];
	SyncOrientation = [dict[@"SyncOrientation"] boolValue];
	UnlockVideoUI = [dict[@"UnlockVideoUI"] boolValue];
	id RotationStyle = dict[@"RotationStyle"];
	rotationStyle = RotationStyle ? [RotationStyle integerValue] : 2;
	id OrientationValue = dict[@"OrientationValue"];
	orientationValue = OrientationValue ? [OrientationValue integerValue] : 1;
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

%group iOS6

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

- (void)accelerometer:(id)accelerometer didChangeDeviceOrientation:(NSInteger)orientation
{
	unlockVideo = [self isCapturingVideo] && UnlockVideoUI;
	%orig;
	unlockVideo = NO;
}

%end

%end

%group preiOS8

%hook PLCameraView

- (NSInteger)_glyphOrientationForCameraOrientation:(NSInteger)orientation
{
	return glyphOrientationOverride(orientation, %orig);
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

%end

%group iOS7

%hook PLCameraView

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

%end

%group iOS8

%hook CAMCaptureController

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

%hook CAMCameraView

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
	CAMCaptureController *cont = [%c(CAMCaptureController) sharedInstance];
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
	CAMCaptureController *cont = [%c(CAMCaptureController) sharedInstance];
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

%end

static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	CamRotateLoader();
}

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, CFSTR("com.PS.CamRotate.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CamRotateLoader();
	if (CamRotateisOn) {
		dlopen("/System/Library/PrivateFrameworks/PhotoLibrary.framework/PhotoLibrary", RTLD_LAZY);
		dlopen("/System/Library/PrivateFrameworks/CameraKit.framework/CameraKit", RTLD_LAZY);
		if (isiOS8Up) {
			%init(iOS8);
		} else {
			%init(preiOS8);
			if (isiOS6) {
				%init(iOS6);
			}
			if (isiOS7) {
				%init(iOS7);
			}
		}
	}
	[pool drain];
}
