#import <UIKit/UIKit.h>
#import "../PS.h"

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
@property(readonly, assign, nonatomic) CAMFlashButton* _flashButton;
- (void)_rotateCameraControlsAndInterface;
@end

@interface CAMCameraView
@property(readonly, assign, nonatomic) CAMFlashButton* _flashButton;
- (void)_rotateCameraControlsAndInterface;
@end

@interface UIView (PhotoLibraryAdditions)
- (void)pl_setHidden:(BOOL)hidden animated:(BOOL)animated;
@end

@interface PLCameraController : NSObject
+ (id)sharedInstance;
- (PLCameraView *)delegate;
- (BOOL)isCapturingVideo;
@end

@interface CAMCameraController : NSObject
+ (id)sharedInstance;
- (CAMCameraView *)delegate;
- (BOOL)isCapturingVideo;
@end

@interface PLUICameraViewController
- (PLCameraView *)_cameraView;
@end

static void CamRotateLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.CamRotate.plist"];
	CamRotateisOn = [[dict objectForKey:@"CamRotateEnabled"] boolValue];
	CamRotateLock = [[dict objectForKey:@"CamRotateLock"] boolValue];
	SyncOrientation = [[dict objectForKey:@"SyncOrientation"] boolValue];
	UnlockVideoUI = [[dict objectForKey:@"UnlockVideoUI"] boolValue];
	id RotationStyle = [dict objectForKey:@"RotationStyle"];
	rotationStyle = RotationStyle ? [RotationStyle integerValue] : 2;
	id OrientationValue = [dict objectForKey:@"OrientationValue"];
	orientationValue = OrientationValue ? [OrientationValue integerValue] : 1;
}


%group COMMON

%hook CameraController

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

%hook CameraView

- (int)_glyphOrientationForCameraOrientation:(int)orientation
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
				return %orig;
		}
	}
	return %orig;
}

%end

%end

%group iOS6

%hook UIImage

+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle
{
	return %orig;
}

%end

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

%group iOS78

%hook CameraView

- (void)_updateEnabledControlsWithReason:(id)reason forceLog:(BOOL)log
{
	%orig;
	if (CamRotateLock)
		[self _rotateCameraControlsAndInterface];
}

- (void)_cameraOrientationChanged:(int)orientation
{
	if ([[%c(PLCameraController) sharedInstance] isCapturingVideo] && UnlockVideoUI) {
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
	id cont;
	Class CameraController = isiOS8 ? objc_getClass("CAMCameraController") : objc_getClass("PLCameraController");
	cont = [CameraController sharedInstance];
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
		NSString *ident = [[NSBundle mainBundle] bundleIdentifier];
		BOOL shouldHook = ([ident isEqualToString:@"com.apple.camera"] || [ident isEqualToString:@"com.apple.springboard"]);
		Class CameraView = isiOS8 ? objc_getClass("CAMCameraView") : objc_getClass("PLCameraView");
		Class CameraController = isiOS8 ? objc_getClass("CAMCameraController") : objc_getClass("PLCameraController");
		if (isiOS6) {
			%init(iOS6);
		} else {
			if ((isiOS7 || isiOS8) && shouldHook) {
				%init(iOS78, CameraView = CameraView);
			}
		}
		%init(COMMON, CameraView = CameraView, CameraController = CameraController);
	}
	[pool drain];
}
