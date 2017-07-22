#import <UIKit/UIKit.h>
#import "Common.h"
#import "../PS.h"
#import "../PSPrefs.x"
#import <substrate.h>

BOOL CamRotateisOn;
BOOL CamRotateLock;
BOOL SyncOrientation;

NSInteger rotationStyle;
NSInteger orientationValue;

HaveCallback() {
    GetPrefs()
    GetBool(CamRotateisOn, @"CamRotateEnabled", YES)
    GetBool(CamRotateLock, @"CamRotateLock", NO)
    GetBool(SyncOrientation, @"SyncOrientation", NO)
    GetInt(rotationStyle, @"RotationStyle", 2)
    GetInt(orientationValue, @"OrientationValue", 1)
}

NSInteger glyphOrientationOverride(NSInteger orig) {
    if (CamRotateLock)
        return orientationValue;
    if (SyncOrientation) {
        UIInterfaceOrientation orient = [UIDevice.currentDevice orientation];
        switch (orient) {
            case UIInterfaceOrientationPortrait:
                return 1;
            case UIInterfaceOrientationPortraitUpsideDown:
                return 2;
            case UIInterfaceOrientationLandscapeLeft:
                return 4;
            case UIInterfaceOrientationLandscapeRight:
                return 3;
        }
    }
    return orig;
}
