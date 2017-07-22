PACKAGE_VERSION = 1.3.4
TARGET = iphone:clang:9.0:5.0

include $(THEOS)/makefiles/common.mk

AGGREGATE_NAME = CamRotateTweak
SUBPROJECTS = CamRotateiOS56 CamRotateiOS78 CamRotateiOS910

include $(THEOS_MAKE_PATH)/aggregate.mk

TWEAK_NAME = CamRotate
CamRotate_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = CamRotateSettings
CamRotateSettings_FILES = CamRotatePreferenceController.m
CamRotateSettings_INSTALL_PATH = /Library/PreferenceBundles
CamRotateSettings_PRIVATE_FRAMEWORKS = Preferences
CamRotateSettings_FRAMEWORKS = Social UIKit
CamRotateSettings_EXTRA_FRAMEWORKS = CepheiPrefs
CamRotateSettings_LDFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/CamRotate.plist$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)
