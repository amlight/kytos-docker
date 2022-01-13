#!/bin/bash

PATCH_BIN=$(which patch)
if [ -z $PATCH_BIN ]; then
	echo "patch not found, please install it"
	exit 1
fi

ORIG_DIR=$(pwd)
KYTOS_DIR=$(python3 -m pip show kytos | grep Location | awk '{print $NF}')
cd $KYTOS_DIR
echo kytos
for PATCH in $(ls -1 $ORIG_DIR/patches/kytos/); do
	echo $PATCH
	$PATCH_BIN -p1 < $ORIG_DIR/patches/kytos/$PATCH
done
cd $ORIG_DIR

for NAPP in $(ls -1 patches/napps/); do
	echo $NAPP
	NAPP_DIR=$(python3 -m pip show $NAPP | grep Location | awk '{print $NF}')
	test -z "$NAPP_DIR" && NAPP_DIR=/src/$(echo $NAPP | tr '_' '-')
	cd $NAPP_DIR
	for PATCH in $(find $ORIG_DIR/patches/napps/$NAPP/ -type f -name '*.patch' | sort); do
		echo $PATCH
		$PATCH_BIN -p1 < $PATCH
	done
done
cd $ORIG_DIR
