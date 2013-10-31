#import <UIKit/UIKit.h>

static BOOL CamRotateisOn;
static BOOL CamRotateLock;
static BOOL SyncOrientation;
static BOOL UnlockVideoUI;
static BOOL unlockVideo = NO;

static int rotationStyle;
static int orientationValue;

#define isiOS6Up (kCFCoreFoundationVersionNumber >= 793.00)

@interface PLCameraController
- (BOOL)isCapturingVideo;
@end

@interface PLCameraView
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
			unlockVideo = NO;
		} else
			%orig;
	} else
		%orig;
}

%end

%hook PLApplicationCameraViewController

- (void)loadView
{
	%orig;
	if (CamRotateisOn) {
		if (rotationStyle == 3 && isiOS6Up) {
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
		if (rotationStyle == 3 && isiOS6Up) {
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
		if (rotationStyle == 3 && isiOS6Up)
			MSHookIvar<int>(self, "_rotationStyle") = 2;
	}
	return %orig;
}

- (void)_setupAnimatePreviewDown:(id)down flipImage:(BOOL)image panoImage:(BOOL)image3 snapshotFrame:(CGRect)frame
{
	%orig;
	if (CamRotateisOn) {
		if (rotationStyle == 3 && isiOS6Up)
			MSHookIvar<int>(self, "_rotationStyle") = -1;
	}
}

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

%hook PLCameraElapsedTimeView

- (void)_setDeviceOrientation:(int)orientation animated:(BOOL)animated
{
	if (CamRotateisOn) {
		if (unlockVideo) return;
	} else
		%orig;
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
  	[pool drain];
}
