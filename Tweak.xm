#import <UIKit/UIKit.h>
#import "Header.h"

static BOOL CamRotateisOn;
static BOOL CamRotateLock;
static BOOL SyncOrientation;
static BOOL UnlockVideoUI;
static BOOL unlockVideo = NO;

static int rotationStyle;
static int orientationValue;

@interface CAMFlashButton : UIControl
@end

@interface PLCameraView
@property(readonly, assign, nonatomic) CAMFlashButton *_flashButton;
- (void)_rotateCameraControlsAndInterface;
@end

@interface CAMCameraView
@property(readonly, assign, nonatomic) CAMFlashButton *_flashButton;
- (void)_rotateCameraControlsAndInterface;
@end

@interface PLCameraController : NSObject
+ (id)sharedInstance;
- (PLCameraView *)delegate;
- (BOOL)isCapturingVideo;
@end

@interface CAMCaptureController : NSObject
+ (id)sharedInstance;
- (CAMCameraView *)delegate;
- (BOOL)isCapturingVideo;
@end

@interface PLUICameraViewController
- (PLCameraView *)_cameraView;
@end

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

static int glyphOrientationOverride(int orientation, int orig)
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
		MSHookIvar<int>(view, "_rotationStyle") = -1;
	}
}

%end

%hook PLUICameraViewController

- (void)viewWillAppear:(BOOL)appear
{
	%orig;
	if (rotationStyle == 3) {
		PLCameraView *view = [self _cameraView];
		MSHookIvar<int>(view, "_rotationStyle") = -1;
	}
}

%end

%hook PLCameraView

- (float)previewImageRotationAngle
{
	if (rotationStyle == 3)
		MSHookIvar<int>(self, "_rotationStyle") = 2;
	return %orig;
}

- (void)_setupAnimatePreviewDown:(id)down flipImage:(BOOL)image panoImage:(BOOL)image3 snapshotFrame:(CGRect)frame
{
	%orig;
	if (rotationStyle == 3)
		MSHookIvar<int>(self, "_rotationStyle") = -1;
}

%end

%hook PLCameraElapsedTimeView

- (void)_setDeviceOrientation:(int)orientation animated:(BOOL)animated
{
	if (unlockVideo)
		return;
	%orig;
}

%end

%hook PLCameraController

- (void)accelerometer:(id)accelerometer didChangeDeviceOrientation:(int)orientation
{
	if ([self isCapturingVideo] && UnlockVideoUI) {
		unlockVideo = YES;
		%orig;
		unlockVideo = NO;
		return;
	}
	%orig;
}

%end

%end

%group preiOS8

%hook PLCameraView

- (int)_glyphOrientationForCameraOrientation:(int)orientation
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
	if (UnlockVideoUI && unlockVideo)
		return NO;
	return %orig;
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

- (void)_cameraOrientationChanged:(int)orientation
{
	id cont = MSHookIvar<id>(self, "_cameraController");
	if ([cont isCapturingVideo] && UnlockVideoUI) {
		unlockVideo = YES;
		%orig;
		unlockVideo = NO;
		return;
	}
	%orig;
}

- (BOOL)_shouldApplyRotationDirectlyToTopBarForOrientation:(int)orientation cameraMode:(int)mode
{
	return rotationStyle == 4 ? YES : %orig;
}

- (void)_updateTopBarStyleForDeviceOrientation:(int)orientation
{
	unlockVideo = UnlockVideoUI;
	PLCameraController *cont = MSHookIvar<PLCameraController *>(self, "_cameraController");
	int origMode = MSHookIvar<int>(cont, "_cameraMode");
	if (origMode == 1 || origMode == 2) {
		%orig;
		unlockVideo = NO;
		return;
	}
	if (rotationStyle == 4) {
		MSHookIvar<int>(cont, "_cameraMode") = 1;
		%orig;
		MSHookIvar<int>(cont, "_cameraMode") = origMode;
	} else
		%orig;
	unlockVideo = NO;
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
	if (UnlockVideoUI && unlockVideo)
		return NO;
	return %orig;
}

%end

%hook CAMCameraView

- (int)_glyphOrientationForCameraOrientation:(int)orientation
{
	return glyphOrientationOverride(orientation, %orig);
}

- (void)_updateEnabledControlsWithReason:(id)reason forceLog:(BOOL)log
{
	%orig;
	if (CamRotateLock)
		[self _rotateCameraControlsAndInterface];
}

- (void)_cameraOrientationChanged:(int)orientation
{
	CAMCaptureController *cont = MSHookIvar<CAMCaptureController *>(self, "_cameraController");
	if ([cont isCapturingVideo] && UnlockVideoUI) {
		unlockVideo = YES;
		%orig;
		unlockVideo = NO;
		return;
	}
	%orig;
}

- (BOOL)_shouldApplyRotationDirectlyToTopBarForOrientation:(int)orientation cameraMode:(int)mode
{
	return rotationStyle == 4 ? YES : %orig;
}

- (void)_updateTopBarStyleForDeviceOrientation:(int)orientation
{
	unlockVideo = UnlockVideoUI;
	CAMCaptureController *cont = MSHookIvar<CAMCaptureController *>(self, "_cameraController");
	int origMode = MSHookIvar<int>(cont, "_cameraMode");
	if (origMode == 1 || origMode == 2) {
		%orig;
		unlockVideo = NO;
		return;
	}
	if (rotationStyle == 4) {
		MSHookIvar<int>(cont, "_cameraMode") = 1;
		%orig;
		MSHookIvar<int>(cont, "_cameraMode") = origMode;
	} else
		%orig;
	unlockVideo = NO;
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
