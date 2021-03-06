#import "../Functions.h"

%group iOS6

%hook PLApplicationCameraViewController

- (void)loadView {
    %orig;
    if (rotationStyle == 3) {
        PLCameraView *view = MSHookIvar<PLCameraView *>(self, "_cameraView");
        MSHookIvar<NSInteger>(view, "_rotationStyle") = -1;
    }
}

%end

%hook PLUICameraViewController

- (void)viewWillAppear: (BOOL)appear {
    %orig;
    if (rotationStyle == 3) {
        PLCameraView *view = [self _cameraView];
        MSHookIvar<NSInteger>(view, "_rotationStyle") = -1;
    }
}

%end

%hook PLCameraView

- (CGFloat)previewImageRotationAngle {
    if (rotationStyle == 3)
        MSHookIvar<NSInteger>(self, "_rotationStyle") = 2;
    return %orig;
}

- (void)_setupAnimatePreviewDown:(id)down flipImage:(BOOL)image panoImage:(BOOL)image3 snapshotFrame:(CGRect)frame {
    %orig;
    if (rotationStyle == 3)
        MSHookIvar<NSInteger>(self, "_rotationStyle") = -1;
}

%end

%end

%hook PLCameraView

- (NSInteger)_glyphOrientationForCameraOrientation: (NSInteger)orientation {
    return glyphOrientationOverride(%orig);
}

%end

%ctor {
    HaveObserver();
    callback();
    if (CamRotateisOn) {
        openCamera6();
        if (isiOS6Up) {
            %init(iOS6);
        }
        %init;
    }
}
