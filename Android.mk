LOCAL_PATH := $(call my-dir)

ifneq ($(filter apollo apollon,$(TARGET_DEVICE)),)
include $(call all-subdir-makefiles,$(LOCAL_PATH))
endif
