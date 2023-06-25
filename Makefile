############################################################################
#			ATBM WiFi Product Select
#CONFIG_ATBM601x: 1T1R 80211b/g/n, HT20
#CONFIG_ATBM602x: 1T1R 80211b/g/n, HT20,HT40
#default CONFIG_ATBM603x
############################################################################

export
CONFIG_ATBM601x = n
CONFIG_ATBM602x = n
CONFIG_ATBM603x = y

############################################################################
#			ATBM WiFi Interface Select
#default CONFIG_ATBM_USB_BUS
############################################################################

export
CONFIG_ATBM_USB_BUS = n
CONFIG_ATBM_SDIO_BUS = y
CONFIG_ATBM_SPI_BUS = n

############################################################################
#		       ATBM WiFi SDIO Interface DPLL Freq Select
#default 40M
############################################################################

export
CONFIG_ATBM_SDIO_40M = n
CONFIG_ATBM_SDIO_24M = n

############################################################################
#
#	The Follow Code Of The Makefile Should Not Be Changed 
#
############################################################################

PWD:=$(shell pwd)
WIFI_INSTALL_DIR := $(PWD)/output

NOSTDINC_FLAGS := -I$(src)/include/ \
	-include $(src)/include/linux/compat-2.6.h \
	-DCOMPAT_STATIC

#####################################################
export
ifeq ($(CONFIG_ATBM601x),y)
CONFIG_NOT_SUPPORT_40M_CHW = y
CONFIG_ATHENAB=y
CONFIG_ARESB=n
CONFIG_ARES=n
MODULES_NAME =  atbm601x_wifi
else ifeq ($(CONFIG_ATBM602x),y)
CONFIG_ATHENAB=y
CONFIG_ARESB=n
CONFIG_ARES=n
MODULES_NAME = atbm602x_wifi
else ifeq ($(CONFIG_ATBM603x),y)
CONFIG_ATHENAB=n
CONFIG_ARESB=y
CONFIG_ARES=n
MODULES_NAME = atbm603x_wifi
endif

ifeq ($(CONFIG_ATBM_USB_BUS),y)
USB_BUS=y
else ifeq ($(CONFIG_ATBM_SDIO_BUS),y)
SDIO_BUS=y
ifeq ($(CONFIG_ATBM_SDIO_24M),y)
CONFIG_ATHENAB_24M=y
CONFIG_ATHENAB=n
else
CONFIG_ATHENAB=y
endif
else ifeq ($(CONFIG_ATBM_SPI_BUS),y)
SPI_BUS=y
endif
MULT_NAME=n
ATBM_MAKEFILE_SUB=y
#####################################################
export 
ifeq ($(CONFIG_ATBM_APOLLO),)
CONFIG_ATBM_APOLLO=m
endif
export
############################################
# Ingenic T31 changes for 603x

CONFIG_ATHENAB=n
CONFIG_ARESB=y
CONFIG_ARES=n

export
SWRATECTRL = y
CONFIG_PM = y
LOAD_FW_H = y
NOTXCONFIRM = y

# this is the Ingenic T31 platform
ATBM_WIFI__EXT_CCFLAGS = -DATBM_WIFI_PLATFORM=22
# this needs to be set to true, otherwise a lot of missing symbols
CONFIG_ATBM_APOLLO_DEBUG=y
############################################
export
include $(src)/Makefile.build.kernel
################### WIRELESS #########################
ifeq ($(CONFIG_ATBM_APOLLO_DEBUG),)
ATBM_WIFI__EXT_CCFLAGS += -DCONFIG_ATBM_APOLLO_DEBUG=1
CONFIG_ATBM_APOLLO_DEBUG=y
endif
#####################################################
export
ifeq ($(CONFIG_MAC80211_ATBM_RC_MINSTREL),)
ATBM_WIFI__EXT_CCFLAGS += -DCONFIG_MAC80211_ATBM_RC_MINSTREL=1
CONFIG_MAC80211_ATBM_RC_MINSTREL=y
endif
ifeq ($(CONFIG_MAC80211_ATBM_RC_MINSTREL_HT),)
ATBM_WIFI__EXT_CCFLAGS += -DCONFIG_MAC80211_ATBM_RC_MINSTREL_HT=1
CONFIG_MAC80211_ATBM_RC_MINSTREL_HT=y
endif

ifeq ($(USB_BUS),y)
HIF:=usb
endif
ifeq ($(SDIO_BUS),y)
HIF:=sdio
endif
ifeq ($(SPI_BUS),y)
HIF:=spi
endif

all: modules install

modules: clean
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KDIR) M=$(shell pwd) modules -j8

strip:
	$(CROSS_COMPILE)strip $(WIFI_INSTALL_DIR)/*.ko --strip-unneeded

install: modules
	mkdir -p $(WIFI_INSTALL_DIR)
	chmod 777 $(WIFI_INSTALL_DIR)
	cp hal_apollo/*.ko $(WIFI_INSTALL_DIR)

clean:
	rm -rf hal_apollo/*.o
	rm -rf hal_apollo/*.ko  
	rm -rf modules.* Module.* 
	make -C $(KDIR) M=$(PWD) ARCH=$(ARCH) clean

hal_clean:
	rm -rf hal_apollo/*.ko
	rm -rf hal_apollo/*.o
	rm -rf hal_apollo/*.mod.c
	rm -rf hal_apollo/*.cmd
