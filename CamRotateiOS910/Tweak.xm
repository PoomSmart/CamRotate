#import "../Functions.h"

%hook CAMViewfinderViewController

%group iOS10Up

- (BOOL)_shouldApplyTopBarRotationForGraphConfiguration: (id)arg1 {
    return rotationStyle == 4 ? YES : %orig;
}

- (NSInteger)_autorotationStyleForLayoutStyle:(NSInteger)layoutStyle {
    return rotationStyle == 3 ? 0 : %orig;
}

- (BOOL)_shouldRotateTopBarForGraphConfiguration:(id)arg1 {
    return rotationStyle == 4 ? YES : %orig;
}

%end

%group iOS9

- (BOOL)_shouldApplyTopBarRotationForMode: (NSInteger)mode device: (NSInteger)device {
    return rotationStyle == 4 ? YES : %orig;
}

- (NSInteger)_autorotationStyle {
    return rotationStyle == 3 ? 0 : %orig;
}

- (BOOL)_shouldRotateTopBarForMode:(NSInteger)mode device:(NSInteger)device {
    return rotationStyle == 4 ? YES : %orig;
}

%end

%end

%hook CAMMotionController

- (NSInteger)captureOrientation {
    return glyphOrientationOverride(%orig);
}

%end

%ctor {
    if (IN_SPRINGBOARD)
        return;
    HaveObserver();
    callback();
    if (CamRotateisOn) {
        openCamera9();
        if (isiOS10Up) {
            %init(iOS10Up);
        } else {
            %init(iOS9);
        }
        %init;
    }
}
