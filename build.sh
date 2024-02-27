#!/usr/bin/env bash
#
# Copyright (C) 2022 - 2024 <abenkenary3@gmail.com>
#

#set -e

KERNELDIR=$(pwd)

# Identity
CODENAME=Hayzel
KERNELNAME=TheOneMemory
VARIANT=EAS
VERSION=4-19

TG_SUPER=1
BOT_BUILD_URL="https://api.telegram.org/bot$TG_TOKEN/sendDocument"

blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo -e "$yellow kernel not found! Cloning..."
git clone --depth=1 --recursive https://$USERNAME:$TOKEN@github.com/Tiktodz/android_kernel_asus_sdm660-4.19 kernel

echo -e "$yellow trb_clang not found! Cloning..."
git clone --depth=1 https://gitlab.com/varunhardgamer/trb_clang -b 17 --single-branch trb_clang

echo -e "$yellow AnyKernel3 not found! Cloning..."
git clone --depth=1 https://github.com/Tiktodz/AnyKernel3 -b 419 AnyKernel3

tg_post_build()
{
	if [ $TG_SUPER = 1 ]
	then
	    curl -F document=@"$1" "$BOT_BUILD_URL" \
	    -F chat_id="$TG_CHAT_ID"  \
	    -F "disable_web_page_preview=true" \
	    -F "parse_mode=Markdown" \
	    -F caption="$2"
	else
	    curl -F document=@"$1" "$BOT_BUILD_URL" \
	    -F chat_id="$TG_CHAT_ID"  \
	    -F "disable_web_page_preview=true" \
	    -F "parse_mode=Markdown" \
	    -F caption="$2"
	fi
}

## Copy this script inside the kernel directory
KERNEL=$KERNELDIR/kernel
TCDIR=$KERNELDIR/trb_clang
KERNEL_DEFCONFIG=asus/X00TD_defconfig
ANYKERNEL3_DIR=$KERNELDIR/AnyKernel3
TZ=Asia/Jakarta
DATE=$(date '+%Y%m%d')
BUILD_START=$(date +"%s")
FINAL_KERNEL_ZIP="$KERNELNAME-$VARIANT-$VERSION-$(date '+%Y%m%d-%H%M')"
KERVER=$(make kernelversion)
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="queen"
export KBUILD_BUILD_HOST=$(source /etc/os-release)
export KBUILD_COMPILER_STRING="$($TCDIR/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
export LLVM=1
export LLVM_IAS=1

# Speed up build process
MAKE="./makeparallel"

# Java
command -v java > /dev/null 2>&1

cd $KERNEL
mkdir -p out
make O=out clean

echo -e "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
echo -e "$blue***********************************************"
echo -e "          BUILDING KERNEL          "
echo -e "$red***********************************************"
make $KERNEL_DEFCONFIG O=out
make -j$(nproc --all) O=out \
	ARCH=arm64 \
	SUBARCH=arm64 \
	PATH="TCDIR/bin:$PATH"
	AS="$TCDIR/bin/llvm-as" \
	CC="$TCDIR/bin/clang" \
	LD="$TCDIR/bin/ld.lld" \
	AR="$TCDIR/bin/llvm-ar" \
	NM="$TCDIR/bin/llvm-nm" \
	STRIP="$TCDIR/bin/llvm-strip" \
	OBJCOPY="$TCDIR/bin/llvm-objcopy" \
	OBJDUMP="$TCDIR/bin/llvm-objdump" \
	CLANG_TRIPLE=aarch64-linux-gnu- \
	CROSS_COMPILE="$TCDIR/bin/clang" \
	CROSS_COMPILE_COMPAT="$TCDIR/bin/clang" \
	CROSS_COMPILE_ARM32="$TCDIR/bin/clang"

echo -e "$blue**** Kernel Compilation Completed ****"

if ! [ -f $KERNEL/out/arch/arm64/boot/Image.gz-dtb ];then
echo -e "$cyan**** Verify Image.gz-dtb ****"
    echo -e "$red Compile Failed!!!$nocol"
    exit 1
fi

# Anykernel 3 time!!
echo -e "$yellow**** Verifying AnyKernel3 Directory ****"
ls $ANYKERNEL3_DIR

# Generating Changelog
echo -e "$red <b><#selectbg_g>$(date)</#></b>"&& echo " " && git log --oneline -n15 | cut -d " " -f 2- | awk '{print "<*> " $(A)}' >> changelog

echo -e "****$nocol Copying Image.gz-dtb ****"
cp $KERNEL/out/arch/arm64/boot/Image.gz-dtb $ANYKERNEL3_DIR/

echo "$cyan**** Time to zip up! ****"
cd $ANYKERNEL3_DIR/

zip -r9 "../$FINAL_KERNEL_ZIP" * -x .git README.md .gitignore zipsigner* "*.zip"

ZIP_FINAL="$FINAL_KERNEL_ZIP"

echo -e "$red**** Done, here is your sha1 ****"

sha1sum $FINAL_KERNEL_ZIP

echo -e "$cyan*** Zip signature ***"
curl -sLo zipsigner-3.0.jar https://github.com/Magisk-Modules-Repo/zipsigner/raw/master/bin/zipsigner-3.0-dexed.jar
java -jar zipsigner-3.0.jar "$ZIP_FINAL".zip "$ZIP_FINAL"-signed.zip
ZIP_FINAL="$ZIP_FINAL-signed"

cd ..

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$cyan Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"

echo -e "$cyan**** Uploading your zip now ****"
tg_post_build "$ZIP_FINAL.zip" "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds"
echo -e "$cyan***********************************************"
echo -e "          HAPPY FLASHING KONTOL          "
echo -e "$yellow***********************************************"

compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
