# /*******************************************************************************
#  * This file is part of the ARK Ledger App.
#  *
#  * Copyright (c) ARK Ecosystem <info@ark.io>
#  *
#  * The MIT License (MIT)
#  *
#  * Permission is hereby granted, free of charge, to any person obtaining a copy
#  * of this software and associated documentation files (the "Software"), to
#  * deal in the Software without restriction, including without limitation the
#  * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
#  * sell copies of the Software, and to permit persons to whom the Software is
#  * furnished to do so, subject to the following conditions:
#  *
#  * The above copyright notice and this permission notice shall be included in
#  * all copies or substantial portions of the Software.
#  *
#  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  * SOFTWARE.
#  *
#  * -----
#  *
#  * Parts of this software are based on Ledger Nano SDK
#  *
#  * (c) 2017 Ledger
#  *
#  * Licensed under the Apache License, Version 2.0 (the "License");
#  * you may not use this file except in compliance with the License.
#  * You may obtain a copy of the License at
#  *
#  *    http://www.apache.org/licenses/LICENSE-2.0
#  *
#  * Unless required by applicable law or agreed to in writing, software
#  * distributed under the License is distributed on an "AS IS" BASIS,
#  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  * See the License for the specific language governing permissions and
#  * limitations under the License.
#  ******************************************************************************/

ifeq ($(BOLOS_SDK),)
    $(error Environment variable BOLOS_SDK is not set)
endif
include $(BOLOS_SDK)/Makefile.defines

APPNAME = Ark
APP_LOAD_PARAMS=--appFlags 0x240 --curve secp256k1 --path "44'/111'" --path "44'/1'" $(COMMON_LOAD_PARAMS)

APPVERSION_M=2
APPVERSION_N=3
APPVERSION_P=0
APPVERSION=$(APPVERSION_M).$(APPVERSION_N).$(APPVERSION_P)

ifeq ($(TARGET_NAME),TARGET_BLUE)
    ICONNAME=blue_app_ark.gif
else ifeq ($(TARGET_NAME),TARGET_NANOS)
    ICONNAME=icons/nanos_app_ark.gif
else
    ICONNAME=icons/nanox_app_ark.gif
endif


################
# Default rule #
################

all: default


############
# Platform #
############

DEFINES     += HAVE_BOLOS_SDK

DEFINES     += OS_IO_SEPROXYHAL
DEFINES     += HAVE_BAGL HAVE_SPRINTF
DEFINES     += HAVE_IO_USB HAVE_L4_USBLIB IO_USB_MAX_ENDPOINTS=4 IO_HID_EP_LENGTH=64 HAVE_USB_APDU
DEFINES     += LEDGER_MAJOR_VERSION=$(APPVERSION_M) LEDGER_MINOR_VERSION=$(APPVERSION_N) LEDGER_PATCH_VERSION=$(APPVERSION_P)
DEFINES     += COMPLIANCE_UX_160
DEFINES     += HAVE_UX_FLOW

# U2F
DEFINES     += HAVE_U2F HAVE_IO_U2F
DEFINES     += USB_SEGMENT_SIZE=64
DEFINES     += BLE_SEGMENT_SIZE=32 #max MTU, min 20
DEFINES     += U2F_PROXY_MAGIC=\"w0w\"
DEFINES     += UNUSED\(x\)=\(void\)x
DEFINES     += APPVERSION=\"$(APPVERSION)\"

#WEBUSB_URL  = www.ledgerwallet.com
#DEFINES     += HAVE_WEBUSB WEBUSB_URL_SIZE_B=$(shell echo -n $(WEBUSB_URL) | wc -c) WEBUSB_URL=$(shell echo -n $(WEBUSB_URL) | sed -e "s/./\\\'\0\\\',/g")
DEFINES   += HAVE_WEBUSB WEBUSB_URL_SIZE_B=0 WEBUSB_URL=""

# Nano X Defines
ifeq ($(TARGET_NAME),TARGET_NANOX)
    DEFINES     += HAVE_BLE BLE_COMMAND_TIMEOUT_MS=2000
    DEFINES     += HAVE_BLE_APDU # basic ledger apdu transport over BLE
endif

ifeq ($(TARGET_NAME),TARGET_NANOS)
    DEFINES     += IO_SEPROXYHAL_BUFFER_SIZE_B=128
else
    DEFINES     += IO_SEPROXYHAL_BUFFER_SIZE_B=300
    DEFINES     += HAVE_GLO096
    DEFINES     += HAVE_BAGL BAGL_WIDTH=128 BAGL_HEIGHT=64
    DEFINES     += HAVE_BAGL_ELLIPSIS # long label truncation feature
    DEFINES     += HAVE_BAGL_FONT_OPEN_SANS_REGULAR_11PX
    DEFINES     += HAVE_BAGL_FONT_OPEN_SANS_EXTRABOLD_11PX
    DEFINES     += HAVE_BAGL_FONT_OPEN_SANS_LIGHT_16PX
    DEFINES     += HAVE_UX_FLOW
endif

# Enabling debug PRINTF
DEBUG = 0
ifneq ($(DEBUG),0)
    ifeq ($(TARGET_NAME),TARGET_NANOS)
        DEFINES   += HAVE_PRINTF PRINTF=screen_printf
    else
        DEFINES   += HAVE_PRINTF PRINTF=mcu_usb_printf
    endif
else
    DEFINES   += PRINTF\(...\)=
endif


##############
# Compiler #
##############

ifneq ($(BOLOS_ENV),)
    $(info BOLOS_ENV=$(BOLOS_ENV))
    CLANGPATH := $(BOLOS_ENV)/clang-arm-fropi/bin/
    GCCPATH := $(BOLOS_ENV)/gcc-arm-none-eabi-5_3-2016q1/bin/
else
    $(info BOLOS_ENV is not set: falling back to CLANGPATH and GCCPATH)
endif

ifeq ($(CLANGPATH),)
    $(info CLANGPATH is not set: clang will be used from PATH)
endif

ifeq ($(GCCPATH),)
    $(info GCCPATH is not set: arm-none-eabi-* will be used from PATH)
endif

CC       := $(CLANGPATH)clang
#CFLAGS   += -O0
CFLAGS   += -O3 -Os

AS      := $(GCCPATH)arm-none-eabi-gcc
LD      := $(GCCPATH)arm-none-eabi-gcc

LDFLAGS += -O3 -Os
LDLIBS  += -lm -lgcc -lc

# import rules to compile glyphs(/pone)
include $(BOLOS_SDK)/Makefile.glyphs

### computed variables
APP_SOURCE_PATH     += src
SDK_SOURCE_PATH     += lib_stusb lib_stusb_impl lib_u2f
SDK_SOURCE_PATH     += lib_ux

ifeq ($(TARGET_NAME),TARGET_NANOX)
    SDK_SOURCE_PATH     += lib_blewbxx lib_blewbxx_impl
endif


load: all
	python3 -m ledgerblue.loadApp $(APP_LOAD_PARAMS)

delete:
	python3 -m ledgerblue.deleteApp $(COMMON_DELETE_PARAMS)

# import generic rules from the sdk
include $(BOLOS_SDK)/Makefile.rules

#add dependency on custom makefile filename
dep/%.d: %.c Makefile.genericwallet


listvariants:
	@echo VARIANTS COIN ark
