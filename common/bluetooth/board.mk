# SPDX-License-Identifier: Apache-2.0

BCB_PATH := $(patsubst $(CURDIR)/%,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
