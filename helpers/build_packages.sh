#!/bin/bash
# droid-hal device packaging converter: from monolithic to modular
# Copyright (c) 2015 Jolla Ltd.
# Contact: Simonas Leleiva <simonas.leleiva@jollamobile.com>

if [ -z $DEVICE ]; then
    echo 'Error: $DEVICE is undefined. Please run hadk'
    exit 1
fi
if [[ ! -d rpm/helpers && ! -d rpm/dhd ]]; then
    echo $0: launch this script from the $ANDROID_ROOT directory
    exit 1
fi

# utilities
. $ANDROID_ROOT/rpm/dhd/helpers/util.sh


if [ ! -d rpm/dhd ]; then
    echo "rpm/dhd/ does not exist, please run migrate first."
    exit 1
fi
LOCAL_REPO=$ANDROID_ROOT/droid-local-repo/$DEVICE
rm -rf $LOCAL_REPO/droid-hal-*
build 
echo "-------------------------------------------------------------------------------"

read -p 'About to perform "Build HA Middleware Packages" HADK chapter. Press Enter to continue.'
sb2 -t $VENDOR-$DEVICE-armv7hl -R -msdk-install ssu domain sales
sb2 -t $VENDOR-$DEVICE-armv7hl -R -msdk-install ssu dr sdk

sb2 -t $VENDOR-$DEVICE-armv7hl -R -msdk-install zypper ref -f
sb2 -t $VENDOR-$DEVICE-armv7hl -R -msdk-install zypper -n install droid-hal-$DEVICE-devel

rm -rf $MER_ROOT/devel/mer-hybris
mkdir -p $MER_ROOT/devel/mer-hybris
pushd $MER_ROOT/devel/mer-hybris

buildmw libhybris || die
sb2 -t $VENDOR-$DEVICE-armv7hl -R -msdk-build zypper -n rm mesa-llvmpipe
buildmw "https://github.com/nemomobile/mce-plugin-libhybris.git" || die
buildmw ngfd-plugin-droid-vibrator || die
buildmw "https://github.com/mer-hybris/pulseaudio-modules-droid.git" rpm/pulseaudio-modules-droid.spec || die
buildmw qt5-feedback-haptics-droid-vibrator || die
buildmw qt5-qpa-hwcomposer-plugin || die
buildmw "https://github.com/mer-hybris/qtscenegraph-adaptation.git" rpm/qtscenegraph-adaptation-droid.spec || die
buildmw "https://github.com/mer-packages/qtsensors.git" || die
buildmw "https://github.com/mer-packages/sensorfw.git" rpm/sensorfw-qt5-hybris.spec || die
read -p '"Build HA Middleware Packages built". Press Enter to continue.'
popd

buildversion
echo "----------------------DONE! Now proceed on creating the rootfs------------------"
