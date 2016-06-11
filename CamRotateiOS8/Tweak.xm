#import "../Functions.h"

%hook CAMCameraView

- (int)_glyphOrientationForCameraOrientation:(int)orientation
{
	return glyphOrientationOverride(%orig);
}

- (void)_updateEnabledControlsWithReason:(id)reason forceLog:(BOOL)log
{
	%orig;
	if (CamRotateLock)
		[self _rotateCameraControlsAndInterface];
}

- (BOOL)_shouldApplyRotationDirectlyToTopBarForOrientation:(int)orientation cameraMode:(int)mode
{
	return rotationStyle == 4 ? YES : %orig;
}

- (void)_updateTopBarStyleForDeviceOrientation:(int)orientation
{
	CAMCaptureController *cont = (CAMCaptureController *)[%c(CAMCaptureController) sharedInstance];
	if (cont) {
		int origMode = MSHookIvar<int>(cont, "_cameraMode");
		if (rotationStyle == 4)
			MSHookIvar<int>(cont, "_cameraMode") = 1;
		%orig;
		MSHookIvar<int>(cont, "_cameraMode") = origMode;
	} else
		%orig;
}

%end

%ctor
{
	NSString *identifier = NSBundle.mainBundle.bundleIdentifier;
	BOOL isSpringBoard = [identifier isEqualToString:@"com.apple.springboard"];
	if (isSpringBoard)
		return;
	HaveObserver()
	callback();
	if (CamRotateisOn) {
		openCamera8();
		%init;
	}
}