ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = YouTube

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = IOSYTPresence

IOSYTPresence_FILES = IOSYTPresence.m
IOSYTPresence_CFLAGS = -fobjc-arc
IOSYTPresence_FRAMEWORKS = Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-package::
	@echo ""
	@echo "=== iOS YouTube Presence Built Successfully ==="
	@echo "The .deb file contains the dylib for injection"
	@echo "Users can extract the dylib and inject into YouTube IPA using:"
	@echo "  - eSign"
	@echo "  - Azula"
	@echo "  - Sideloadly with injection"
	@echo ""
