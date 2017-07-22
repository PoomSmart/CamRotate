#import "../Functions.h"

%hook CameraView

- (NSInteger)_glyphOrientationForCameraOrientation: (NSInteger)orientation {
    return glyphOrientationOverride(%orig);
}

- (void)_updateEnabledControlsWithReason:(id)reason forceLog:(BOOL)log {
    %orig;
    if (CamRotateLock)
        [self _rotateCameraControlsAndInterface];
}

- (BOOL)_shouldApplyRotationDirectlyToTopBarForOrientation:(NSInteger)orientation cameraMode:(NSInteger)mode {
    return rotationStyle == 4 ? YES : %orig;
}

- (void)_updateTopBarStyleForDeviceOrientation:(NSInteger)orientation {
    id cont = %c(CAMCaptureController) ? [%c(CAMCaptureController) sharedInstance] : [%c(PLCameraController) sharedInstance];
    if (cont) {
        NSInteger origMode = MSHookIvar<NSInteger>(cont, "_cameraMode");
        if (rotationStyle == 4)
            MSHookIvar<NSInteger>(cont, "_cameraMode") = 1;
        %orig;
        MSHookIvar<NSInteger>(cont, "_cameraMode") = origMode;
    } else
        %orig;
}

%end

%ctor {
    if (IN_SPRINGBOARD)
        return;
    HaveObserver();
    callback();
    if (CamRotateisOn) {
        if (isiOS8Up)
            openCamera8();
        else
            openCamera7();
        %init(CameraView = objc_getClass("CAMCameraView") ? objc_getClass("CAMCameraView") : objc_getClass("PLCameraView"));
    }
}
