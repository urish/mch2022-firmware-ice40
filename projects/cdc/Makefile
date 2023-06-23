# Project config
PROJ := cdc

PROJ_DEPS := 
PROJ_RTL_SRCS := $(addprefix rtl/, \
	prescaler.v \
	usb_cdc/usb_cdc/bulk_endp.v \
  usb_cdc/usb_cdc/ctrl_endp.v \
  usb_cdc/usb_cdc/in_fifo.v \
  usb_cdc/usb_cdc/out_fifo.v \
  usb_cdc/usb_cdc/phy_rx.v \
  usb_cdc/usb_cdc/phy_tx.v \
  usb_cdc/usb_cdc/sie.v \
  usb_cdc/usb_cdc/usb_cdc.v \
)
PROJ_TOP_SRC := rtl/cdc.v
PROJ_TOP_MOD := top

NEXTPNR_SEED ?= 2159
NEXTPNR_ARGS = --no-promote-globals --seed $(NEXTPNR_SEED)

# Include default rules
include ../_common/build.mk
