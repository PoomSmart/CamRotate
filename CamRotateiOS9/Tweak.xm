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

%ctor
{
	NSString *identifier = NSBundle.mainBundle.bundleIdentifier;
	BOOL isSpringBoard = [identifier isEqualToString:@"com.apple.springboard"];
	if (isSpringBoard)
		return;
	HaveObserver()
	callback();
	if (CamRotateisOn) {
		openCamera9();
		%init;
	}
}