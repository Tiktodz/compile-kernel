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

# Clone Kernulnya Boys
git clone --depth 1 --recursive https://$USERNAME:$TOKEN@github.com/Tiktodz/android_kernel_asus_sdm660-4.19 kernel

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

# Prepare
KERNEL_ROOTDIR="${MainPath}"/kernel # IMPORTANT ! Fill with your kernel source root directory.
export TZ=Asia/Jakarta # Change with your local timezone.
export LD="ld.lld"
export KERNELNAME=TheOneMemory # Change with your localversion name or else.
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

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"
}

# Compile
compile(){
cd ${KERNEL_ROOTDIR}
export HASH_HEAD=$(git rev-parse --short HEAD)
export COMMIT_HEAD=$(git log --oneline -1)
export LD_LIBRARY_PATH="${ClangPath}/lib:${LD_LIBRARY_PATH}"

make -j$(nproc --all) O=out ARCH=arm64 asus/X00TD_defconfig
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
  git clone https://github.com/Tiktodz/AnyKernel3 -b 419 AnyKernel
  cp -af "$IMAGE" AnyKernel/Image.gz-dtb
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@"$ZIP" "$BOT_BUILD_URL" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=Markdown" \
        -F caption="Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For *${DEVICE_CODENAME}* | *${KBUILD_COMPILER_STRING}*"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="I'm tired of compiling kernels,And I choose to give up...please give me motivation"
    exit 1
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 "[KSU]$KERNELNAME-X00TD-4-19-$DATE.zip" *
    cd ..
}

tg_post_msg "<b>Warning!!</b>%0AStart Building ${KERNELNAME} for ${DEVICE_CODENAME}"
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
