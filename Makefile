ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = YouTube

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = IOSYTPresence

IOSYTPresence_FILES = Tweak.x
IOSYTPresence_CFLAGS = -fobjc-arc
IOSYTPresence_FRAMEWORKS = Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
