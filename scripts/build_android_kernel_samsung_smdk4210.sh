#!/bin/bash

clear
echo
echo "Welcome to MaxFu's Kernel Builder"

echo 
echo "Setting up parameters......"
GOON=$(cat /dev/urandom | head -1 | md5sum | head -c 3)
PLACE=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
PREFIX=sources
NAME=$(whoami)
if [ "$1" = "" ]; then
    HOST=test
    VERSION=$(date +v%y.%m.%d.%H%M)
else
    HOST=release
    VERSION=$1
fi
KNAME=HydraNirvana
KFILE=$NAME"_"$KNAME"_"$VERSION
ARCH=arm
DEFCONFIG=q1_speedmod_defconfig
PLATFORM=linux
# PLATFORM=cygwin
KSOURCE=android_kernel_samsung_smdk4210
ISOURCE=initramfs_speedmod_combined
# ISOURCE=initramfs_n7000
FSOURCE=hydracorenirvana_flashable
TSOURCE=toolchains
STEMP=source_temp
ITEMP=initramfs_temp
FTEMP=flashable_temp
TTEMP=toolchain_temp
TCNAME=arm-linux-androideabi
# TCVERSION=4.6
# TCVERSION=4.6.3
# TCVERSION=4.7
TCVERSION=4.7.linaro
TCROOT=$TSOURCE/$PLATFORM/$TCNAME-$TCVERSION
TOOLCHAIN=$TTEMP/bin/$TCNAME-
SROOT=$TTEMP/sysroot
echo "Done."

echo 
echo "Wiping for new build......"
cd $PLACE/ > /dev/null
find . -name "*~" -exec rm -fv {} \; > /dev/null
rm -rf $PLACE/$KFILE > /dev/null
rm -rf $PLACE/$STEMP > /dev/null
rm -rf $PLACE/$ITEMP > /dev/null
rm -rf $PLACE/$FTEMP > /dev/null
rm -rf $PLACE/$TTEMP > /dev/null
echo "Done."

echo
echo "Preparing temp folders......"
cd $PLACE/ > /dev/null
mkdir $PLACE/$KFILE > /dev/null
mkdir $PLACE/$KFILE/Modules > $PLACE/$KFILE/Compilelog.txt
cp -rf $PLACE/$PREFIX/$KSOURCE $PLACE/$STEMP >> $PLACE/$KFILE/Compilelog.txt
cp -rf $PLACE/$PREFIX/$ISOURCE $PLACE/$ITEMP >> $PLACE/$KFILE/Compilelog.txt
cp -rf $PLACE/$PREFIX/$FSOURCE $PLACE/$FTEMP >> $PLACE/$KFILE/Compilelog.txt
cp -rf $PLACE/$PREFIX/$TCROOT  $PLACE/$TTEMP >> $PLACE/$KFILE/Compilelog.txt
rm -rf $PLACE/$FTEMP/.git >> $PLACE/$KFILE/Compilelog.txt
rm -rf $PLACE/$ITEMP/.git >> $PLACE/$KFILE/Compilelog.txt
rm -f $PLACE/$FTEMP/README.md >> $PLACE/$KFILE/Compilelog.txt
rm -f $PLACE/$ITEMP/README.md >> $PLACE/$KFILE/Compilelog.txt
echo "Done."

echo
echo "Preparing defconfig......"
cd $PLACE/$STEMP/ >> $PLACE/$KFILE/Compilelog.txt
export USE_SEC_FIPS_MODE=true
export CROSS_COMPILE=$PLACE/$TOOLCHAIN
sed -i "s/CONFIG_CROSS_COMPILE=*.*/CONFIG_CROSS_COMPILE=\"$(echo $PLACE/$TOOLCHAIN | sed 's#\/#\\\/#g')\"/g" $PLACE/$STEMP/arch/$ARCH/configs/$DEFCONFIG
sed -i "s/CONFIG_INITRAMFS_SOURCE=*.*/CONFIG_INITRAMFS_SOURCE=\"$(echo $PLACE/$ITEMP | sed 's#\/#\\\/#g')\"/g" $PLACE/$STEMP/arch/$ARCH/configs/$DEFCONFIG
sed -i "s/CONFIG_LOCALVERSION_AUTO/CONFIG_MAXFULOCALVERSION_AUTO/g" $PLACE/$STEMP/arch/$ARCH/configs/$DEFCONFIG
sed -i "s/CONFIG_LOCALVERSION=*.*/CONFIG_LOCALVERSION=\"$(echo "_"$KNAME"_"$VERSION)\"/g" $PLACE/$STEMP/arch/$ARCH/configs/$DEFCONFIG
sed -i "s/CONFIG_MAXFULOCALVERSION_AUTO/CONFIG_LOCALVERSION_AUTO/g" $PLACE/$STEMP/arch/$ARCH/configs/$DEFCONFIG
sed -i "s/hardcore/$NAME/g" $PLACE/$STEMP/scripts/mkcompile_h
sed -i "s/speedmod-n7000-jb/$HOST/g" $PLACE/$STEMP/scripts/mkcompile_h
grep "sysroot" $PLACE/$STEMP/Makefile >> $PLACE/$KFILE/Compilelog.txt
if [ $? = "0" ]; then
    if [ -d "$PLACE/$SROOT" ]; then
        sed -i "s/--sysroot=*.*/--sysroot=$(echo $PLACE/$SROOT' \\' | sed 's#\/#\\\/#g')/g" $PLACE/$STEMP/Makefile
    else
        sed -i "/--sysroot/d" $PLACE/$STEMP/Makefile
    fi
fi
sed -i "s/@@MAXFUNAME@@/$KNAME/g" $PLACE/$FTEMP/system/nirvana.prop
sed -i "s/@@MAXFUNAME@@/$KNAME/g" $PLACE/$FTEMP/META-INF/com/google/android/aroma/cn.lang
sed -i "s/@@MAXFUNAME@@/$KNAME/g" $PLACE/$FTEMP/META-INF/com/google/android/aroma/en.lang
sed -i "s/@@MAXFUNAME@@/$KNAME/g" $PLACE/$FTEMP/META-INF/com/google/android/aroma/showtext.txt
sed -i "s/@@MAXFUNAME@@/$KNAME/g" $PLACE/$FTEMP/META-INF/com/google/android/updater-script
sed -i "s/@@MAXFUNAME@@/$KNAME/g" $PLACE/$FTEMP/META-INF/com/google/android/aroma-config
sed -i "s/@@MAXFUVERS@@/$VERSION/g" $PLACE/$FTEMP/META-INF/com/google/android/aroma-config
sed -i "s/@@MAXFUAUTH@@/$NAME/g" $PLACE/$FTEMP/META-INF/com/google/android/aroma-config
sed -i "s/@@MAXFUDATE@@/$(date +%Y-%m-%d)/g" $PLACE/$FTEMP/META-INF/com/google/android/aroma-config
date >> $PLACE/$KFILE/Compilelog.txt
make clean >> $PLACE/$KFILE/Compilelog.txt
make $DEFCONFIG >> $PLACE/$KFILE/Compilelog.txt
echo "Done."

echo
echo "Compiling modules......"
date >> $PLACE/$KFILE/Compilelog.txt
make clean >> $PLACE/$KFILE/Compilelog.txt
make modules >> $PLACE/$KFILE/Compilelog.txt
cp -af $(find . -name *.ko -print |grep -v $ITEMP) $PLACE/$KFILE/Modules/ >> $PLACE/$KFILE/Compilelog.txt
$PLACE/$TOOLCHAIN"strip" --strip-debug $PLACE/$KFILE/Modules/*.ko >> $PLACE/$KFILE/Compilelog.txt
cp -af $PLACE/$KFILE/Modules/*.ko $PLACE/$ITEMP/lib/modules/ >> $PLACE/$KFILE/Compilelog.txt
chmod -R g-w $PLACE/$ITEMP/* >> $PLACE/$KFILE/Compilelog.txt
echo "Done."

echo
echo "Compiling the kernel......"
cd $PLACE/$STEMP/ >> $PLACE/$KFILE/Compilelog.txt
date >> $PLACE/$KFILE/Compilelog.txt
make clean >> $PLACE/$KFILE/Compilelog.txt
make >> $PLACE/$KFILE/Compilelog.txt
cp $PLACE/$STEMP/arch/$ARCH/boot/zImage $PLACE/$FTEMP/ >> $PLACE/$KFILE/Compilelog.txt
echo "Done."

echo
echo "Making flashable files......"
cd $PLACE/$FTEMP/ >> $PLACE/$KFILE/Compilelog.txt
zip -r $PLACE/$KFILE/$KFILE".zip" * >> $PLACE/$KFILE/Compilelog.txt
tar -H ustar -cvf $PLACE/$KFILE/$KFILE".tar" zImage >> $PLACE/$KFILE/Compilelog.txt
echo "Done"

echo
echo "Write your changelog. When you finished, input \"$GOON\" to go on."
echo 'Information:' > $PLACE/$KFILE/README.txt
echo 'Name:    '$KNAME >> $PLACE/$KFILE/README.txt
echo 'Author:  '$NAME >> $PLACE/$KFILE/README.txt
echo 'Version: '$VERSION >> $PLACE/$KFILE/README.txt
if [ "$1" = "" ]; then
    echo 'Status:  Test build' >> $PLACE/$KFILE/README.txt
else
    echo 'Status:  Release build' >> $PLACE/$KFILE/README.txt
fi
echo 'Thread:  http://forum.xda-developers.com/showthread.php?t=2053084' >> $PLACE/$KFILE/README.txt
read -p "INPUT > " INPUT
if [ "$INPUT" = "$GOON" ]; then
    echo "There is no changelog."
else
    echo "" >> $PLACE/$KFILE/README.txt
    echo "Changelog:" >> $PLACE/$KFILE/README.txt
    COUNTER=1
    while true; do
        if [ "$INPUT" = "$GOON" ]; then
            break
        else
            echo $COUNTER".""$INPUT" >> $PLACE/$KFILE/README.txt
            COUNTER=$(expr $COUNTER + 1)
            read -p "INPUT > " INPUT
        fi
    done
fi
echo "" >> $PLACE/$KFILE/README.txt
echo "MD5 Checksum:" >> $PLACE/$KFILE/README.txt
md5sum -b $PLACE/$KFILE/$KFILE".zip" >> $PLACE/$KFILE/README.txt
md5sum -b $PLACE/$KFILE/$KFILE".tar" >> $PLACE/$KFILE/README.txt
echo "Done"

echo 
echo "Wiping temp stuff......"
cd $PLACE/ >> $PLACE/$KFILE/Compilelog.txt
rm -rf $PLACE/$STEMP >> $PLACE/$KFILE/Compilelog.txt
rm -rf $PLACE/$ITEMP >> $PLACE/$KFILE/Compilelog.txt
rm -rf $PLACE/$FTEMP >> $PLACE/$KFILE/Compilelog.txt
rm -rf $PLACE/$TTEMP >> $PLACE/$KFILE/Compilelog.txt
echo "Done."

echo 
echo 'Compile Complete. Your result is in '$PLACE/$KFILE'.'
