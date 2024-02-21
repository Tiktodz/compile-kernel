#!/usr/bin/env bash
#
# Copyright (C) 2022 <abenkenary3@gmail.com>
#

# Main
MainPath=$(pwd)
# MainClangPath="${MainPath}/clang"
# MainClangZipPath="${MainPath}/clang-zip"
# ClangPath="${MainClangZipPath}"
# GCCaPath="${MainPath}/GCC64"
# GCCbPath="${MainPath}/GCC32"
# MainZipGCCaPath="${MainPath}/GCC64-zip"
# MainZipGCCbPath="${MainPath}/GCC32-zip"

# Identity
CODENAME=Hayzel
KERNELNAME=TheOneMemory
VARIANT=HMP
VERSION=CLO

# Clone Kernulnya Boys
git clone --depth=1 --recursive https://$USERNAME:$TOKEN@github.com/Tiktodz/android_kernel_asus_sdm636 kernel

# Clone TeeRBeh Clang
git clone --depth=1 https://gitlab.com/varunhardgamer/trb_clang.git -b 17 --single-branch clang

# ClangPath=${MainClangZipPath}
ClangPath="${MainPath}/clang"
[[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
# mkdir $ClangPath
# rm -rf $ClangPath/*
# wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-r487747c.tar.gz -O "clang-r487747c.tar.gz"
# tar -xf clang-r487747c.tar.gz -C $ClangPath

# mkdir $GCCaPath
# mkdir $GCCbPath
# wget -q https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/tags/android-12.1.0_r27.tar.gz -O "gcc64.tar.gz"
# tar -xf gcc64.tar.gz -C $GCCaPath
# wget -q https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/+archive/refs/tags/android-12.1.0_r27.tar.gz -O "gcc32.tar.gz"
# tar -xf gcc32.tar.gz -C $GCCbPath

# The name of the device for which the kernel is built
MODEL="Asus Zenfone Max Pro M1"

# Prepare
KERNEL_ROOTDIR="${MainPath}"/kernel # IMPORTANT ! Fill with your kernel source root directory.
export TZ=Asia/Jakarta # Change with your local timezone.
export LD="ld.lld"
export KBUILD_BUILD_USER=queen # Change with your own name or else.
IMAGE="${KERNEL_ROOTDIR}"/out/arch/arm64/boot/Image.gz-dtb
CLANG_VER="$("$ClangPath"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
#LLD_VER="$("$ClangPath"/bin/ld.lld --version | head -n 1)"
export KBUILD_COMPILER_STRING="$CLANG_VER"
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M")
START=$(date +"%s")
# PATH=${ClangPath}/bin:${GCCaPath}/bin:${GCCbPath}/bin:${PATH}
export PATH="${ClangPath}"/bin:${PATH}
 
# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"
export BOT_BUILD_URL="https://api.telegram.org/bot$TG_TOKEN/sendDocument"
export STICKER="https://api.telegram.org/bot$TG_TOKEN/sendSticker"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"
}

tg_send_sticker() {
    curl -s -X POST "$STICKER" \
        -d sticker="$1" \
        -d chat_id="$TG_CHAT_ID"
}

# Check Kernel Version
KERVER=$(make kernelversion)

# Compile
compile(){
cd ${KERNEL_ROOTDIR}
export SID="CAACAgUAAxkBAAERkqll1aooPLOdy9vohfuAt0sIAW34PwACWgADZ7RFFph-0udETtQqNAQ"
export STICK="CAACAgUAAxkBAAERkTtl1RQCf9jzTxxJ4DzpVwrPuOOG9QACXAADZ7RFFr72cNXFq8_jNAQ"
export HASH_HEAD=$(git rev-parse --short HEAD)
export COMMIT_HEAD=$(git log --oneline -1)
export LD_LIBRARY_PATH="${ClangPath}/lib:${LD_LIBRARY_PATH}"

make -j$(nproc --all) O=out ARCH=arm64 X00TD_defconfig
make -j$(nproc --all) ARCH=arm64 SUBARCH=arm64 O=out \
    CC=${ClangPath}/bin/clang \
    NM=${ClangPath}/bin/llvm-nm \
    CXX=${ClangPath}/bin/clang++ \
    AR=${ClangPath}/bin/llvm-ar \
    STRIP=${ClangPath}/bin/llvm-strip \
    HOST_PREFIX=${ClangPath}/bin/llvm-objcopy \
    OBJDUMP=${ClangPath}/bin/llvm-objdump \
    OBJSIZE=${ClangPath}/bin/llvm-size \
    READELF=${ClangPath}/bin/llvm-readelf \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    HOSTAR=${ClangPath}/bin/llvm-ar \
    HOSTCC=${ClangPath}/bin/clang \
    HOSTCXX=${ClangPath}/bin/clang++

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi
  cd ${KERNEL_ROOTDIR}
  git clone https://github.com/Tiktodz/AnyKernel3 -b hmp-old AnyKernel
  cp -af "$IMAGE" AnyKernel/Image.gz-dtb
}

# Push kernel to channel
function push() {
    cd AnyKernel
    MD5CHECK=$(md5sum "$ZIP_FINAL" | cut -d' ' -f1)
    curl -F document=@"$ZIP_FINAL" "$BOT_BUILD_URL" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=Markdown" \
        -F caption="Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For *${MODEL}* | *${KBUILD_COMPILER_STRING}*"
}

# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="I'm tired of compiling kernels,And I choose to give up...please give me motivation"
    tg_send_sticker "$STICK"
    exit 1
}

# Zipping
function zipping() {
        cd AnyKernel || exit 1
        cp -af $KERNEL_DIR/init.$CODENAME.Spectrum.rc spectrum/init.spectrum.rc && sed -i "s/persist.spectrum.kernel.*/persist.spectrum.kernel TheOneMemory/g" spectrum/init.spectrum.rc
        cp -af $KERNEL_DIR/changelog META-INF/com/google/android/aroma/changelog.txt
        cp -af anykernel-real.sh anykernel.sh
        sed -i "s/kernel.string=.*/kernel.string=$KERNELNAME/g" anykernel.sh
        sed -i "s/kernel.type=.*/kernel.type=$VARIANT/g" anykernel.sh
        sed -i "s/kernel.for=.*/kernel.for=$CODENAME/g" anykernel.sh
        sed -i "s/kernel.compiler=.*/kernel.compiler=$KBUILD_COMPILER_STRING/g" anykernel.sh
        sed -i "s/kernel.made=.*/kernel.made=dotkit @fakedotkit/g" anykernel.sh
        sed -i "s/kernel.version=.*/kernel.version=$KERVER/g" anykernel.sh
        sed -i "s/message.word=.*/message.word=Appreciate your efforts for choosing TheOneMemory kernel./g" anykernel.sh
        sed -i "s/build.date=.*/build.date=$DATE/g" anykernel.sh
        sed -i "s/build.type=.*/build.type=$BASE/g" anykernel.sh
        sed -i "s/supported.versions=.*/supported.versions=9-13/g" anykernel.sh
        sed -i "s/device.name1=.*/device.name1=X00TD/g" anykernel.sh
        sed -i "s/device.name2=.*/device.name2=X00T/g" anykernel.sh
        sed -i "s/device.name3=.*/device.name3=Zenfone Max Pro M1 (X00TD)/g" anykernel.sh
        sed -i "s/device.name4=.*/device.name4=ASUS_X00TD/g" anykernel.sh
        sed -i "s/device.name5=.*/device.name5=ASUS_X00T/g" anykernel.sh
        sed -i "s/X00TD=.*/X00TD=1/g" anykernel.sh
        cd META-INF/com/google/android
        sed -i "s/KNAME/$KERNELNAME/g" aroma-config
        sed -i "s/KVER/$KERVER/g" aroma-config
        sed -i "s/KAUTHOR/dotkit @fakedotkit/g" aroma-config
        sed -i "s/KDEVICE/Zenfone Max Pro M1/g" aroma-config
        sed -i "s/KBDATE/$DATE/g" aroma-config
        sed -i "s/KVARIANT/$VARIANT/g" aroma-config
        cd ../../../..

        zip -r9 $KERNELNAME-$CODENAME-$VARIANT-"$DATE" * -x .git README.md anykernel-real.sh .gitignore zipsigner* "*.zip"

        ZIP_FINAL="$KERNELNAME-$CODENAME-$VARIANT-$DATE"

        msg "|| Signing Zip ||"
        tg_post_msg "<code>🔑 Signing Zip file with AOSP keys..</code>"

        curl -sLo zipsigner-3.0.jar https://github.com/Magisk-Modules-Repo/zipsigner/raw/master/bin/zipsigner-3.0-dexed.jar
        java -jar zipsigner-3.0.jar "$ZIP_FINAL".zip "$ZIP_FINAL"-signed.zip
        ZIP_FINAL="$ZIP_FINAL-signed"
        cd ..
}

tg_send_sticker "$SID"
tg_post_msg "<b>Warning!!</b>%0AStart Building ${KERNELNAME} for ${MODEL}"
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
