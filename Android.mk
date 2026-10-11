LOCAL_PATH := $(call my-dir)

ifneq ($(filter apollon,$(TARGET_DEVICE)),)
include $(call all-subdir-makefiles,$(LOCAL_PATH))
endif
