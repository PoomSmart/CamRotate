#import "../Functions.h"

%hook CAMViewfinderViewController

- (_Bool)_shouldApplyTopBarRotationForGraphConfiguration:(id)arg1
{
	return rotationStyle == 4 ? YES : %orig;
}

- (NSInteger)_autorotationStyleForLayoutStyle:(NSInteger)layoutStyle
{
	return rotationStyle == 3 ? 0 : %orig;
}

- (_Bool)_shouldRotateTopBarForGraphConfiguration:(id)arg1
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