GO_EASY_ON_ME = 1
SDKVERSION = 7.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk
TWEAK_NAME = CamRotate
CamRotate_FILES = Tweak.xm
CamRotate_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = CamRotateSettings
CamRotateSettings_FILES = CamRotatePreferenceController.m
CamRotateSettings_INSTALL_PATH = /Library/PreferenceBundles
CamRotateSettings_PRIVATE_FRAMEWORKS = Preferences
CamRotateSettings_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/CamRotate.plist$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)
