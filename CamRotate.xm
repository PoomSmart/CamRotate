#import <UIKit/UIKit.h>

static BOOL CamRotateisOn;
static BOOL CamRotateLock;
static BOOL SyncOrientation;
static BOOL UnlockVideoUI;
static BOOL unlockVideo = NO;
static BOOL TFVInstalled;

static int rotationStyle;
static int orientationValue;

#define isiOS6 (kCFCoreFoundationVersionNumber == 793.00)
#define isiOS7 (kCFCoreFoundationVersionNumber > 793.00)

@interface CAMFlashButton : UIControl
@end

@interface PLCameraView
@property(readonly, assign, nonatomic) CAMFlashButton* _flashButton;
@end

@interface UIView (PhotoLibraryAdditions)
- (void)pl_setHidden:(BOOL)hidden animated:(BOOL)animated;
@end

@interface PLCameraController : NSObject
+ (id)sharedInstance;
- (PLCameraView *)delegate;
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


%hook UIImage

+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle
{
	return %orig;
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
	if (CamRotateisOn) {
		if (UnlockVideoUI && unlockVideo)
			return NO;
		return %orig;
	}
	return %orig;
}

- (void)accelerometer:(id)accelerometer didChangeDeviceOrientation:(int)orientation
{
	if (CamRotateisOn) {
		if ([self isCapturingVideo] && UnlockVideoUI) {
			unlockVideo = YES;
			%orig;
			if (TFVInstalled) {
				if ([[[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.ToggleFlashVideo.plist"] objectForKey:@"TFVNative"] boolValue])
					[[self delegate]._flashButton pl_setHidden:NO animated:NO];
			}
			unlockVideo = NO;
		} else
			%orig;
	} else
		%orig;
}

%end

%hook PLCameraView

- (int)_glyphOrientationForCameraOrientation:(int)orientation
{
	if (CamRotateisOn) {
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
	}
	return %orig;
}

%end

%group iOS6

%hook PLApplicationCameraViewController

- (void)loadView
{
	%orig;
	if (CamRotateisOn) {
		if (rotationStyle == 3) {
			PLCameraView *view = MSHookIvar<PLCameraView *>(self, "_cameraView");
			MSHookIvar<int>(view, "_rotationStyle") = -1;
		}
	}
}

%end

%hook PLUICameraViewController

- (void)viewWillAppear:(BOOL)appear
{
	%orig;
	if (CamRotateisOn) {
		if (rotationStyle == 3) {
			PLCameraView *view = [self _cameraView];
			MSHookIvar<int>(view, "_rotationStyle") = -1;
		}
	}
}

%end

%hook PLCameraView

- (float)previewImageRotationAngle
{
	if (CamRotateisOn) {
		if (rotationStyle == 3)
			MSHookIvar<int>(self, "_rotationStyle") = 2;
	}
	return %orig;
}

- (void)_setupAnimatePreviewDown:(id)down flipImage:(BOOL)image panoImage:(BOOL)image3 snapshotFrame:(CGRect)frame
{
	%orig;
	if (CamRotateisOn) {
		if (rotationStyle == 3)
			MSHookIvar<int>(self, "_rotationStyle") = -1;
	}
}

%end

%hook PLCameraElapsedTimeView

- (void)_setDeviceOrientation:(int)orientation animated:(BOOL)animated
{
	if (CamRotateisOn) {
		if (unlockVideo) return;
	} else
		%orig;
}

%end

%end

%group iOS7

%hook PLCameraView

- (BOOL)_shouldApplyRotationDirectlyToTopBarForOrientation:(int)orientation cameraMode:(int)mode
{
	return CamRotateisOn && rotationStyle == 4 ? YES : %orig;
}

- (void)_updateTopBarStyleForDeviceOrientation:(int)orientation
{
	if (CamRotateisOn && rotationStyle == 4) {
		PLCameraController *cont = [%c(PLCameraController) sharedInstance];
		int origMode = MSHookIvar<int>(cont, "_cameraMode");
		MSHookIvar<int>(cont, "_cameraMode") = 1;
		%orig;
		MSHookIvar<int>(cont, "_cameraMode") = origMode;
	} else
		%orig;
}

%end

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
	TFVInstalled = NO;
	if (isiOS6)
		%init(iOS6);
	else {
		if (isiOS7) {
			if (dlopen("/Library/MobileSubstrate/DynamicLibraries/ToggleFlashVideo.dylib", RTLD_LAZY) != NULL)
				TFVInstalled = YES;
			%init(iOS7);
		}
	}
	%init();
	[pool drain];
}
