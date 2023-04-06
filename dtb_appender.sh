#!/bin/bash

####	Exit immediately if anything fails

set -e

OG_DTB_FILE="/boot/dtbs/$(uname -r)/rockchip/rk3399-rockpro64.dtb"
WORK_DIR="/boot/dtbs/dtb-workspace"
trap 'echo "deleting workspace directory"; rm -rf "$WORK_DIR"' EXIT
APPENDABLES_DIR="/boot/dtbs/appendables"

####	check if appendables file exists
if [ ! -d "$APPENDABLES_DIR" ]; then
  echo "No appendables dir, creating it"
  mkdir "$APPENDABLES_DIR"
fi

APPENDABLES=$(find $APPENDABLES_DIR -name "*.dts" -print)
if [ ! -d "$WORK_DIR" ]; then
  echo "Creating workspace directory: $WORK_DIR"
  mkdir -p "$WORK_DIR"
fi
####	check if some file exists
if [ ! -n "$APPENDABLES" ]; then
  echo "No appendable files found in $APPENDABLES_DIR"
  echo "Add your dts files to $APPENDABLES_DIR and they will get appended to the base dtb when you run this script"
  exit 1
fi

####	decompile the dtb into base.dts

dtc -q -I dtb -O dts -o $WORK_DIR/base.dts $OG_DTB_FILE

echo "original dtb decompiled"
####	concatenate the base dts file with the append file

cat $WORK_DIR/base.dts $APPENDABLES > $WORK_DIR/merged.dts

echo "edits appended"
####	recompile the result into merged.dtb

dtc -q -I dts -O dtb -o $WORK_DIR/merged.dtb $WORK_DIR/merged.dts

echo "edited dtb successfully compiled"

####	apply the new dtb if anything has changed

if ! cmp -s "${OG_DTB_FILE}" "$WORK_DIR/merged.dtb"; then
  echo "changes found, writing new dtb"
  cp "$WORK_DIR/merged.dtb" "${OG_DTB_FILE}"
else
  echo "no changes, not writing new dtb"
fi
