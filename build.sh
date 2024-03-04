#!/usr/bin/env bash
#
# Copyright (C) 2022 <abenkenary3@gmail.com>
#

#set -e

msg() {
    echo -e "\e[1;32m$*\e[0m"
}

err() {
    echo -e "\e[1;41m$*\e[0m"
}

cdir() {
	cd "$1" 2>/dev/null || \
		err "The directory $1 doesn't exists !"
}

# Main
MainPath=$(pwd)
# MainClangPath="${MainPath}/clang"
# MainClangZipPath="${MainPath}/clang-zip"
# ClangPath="${MainClangZipPath}"
# GCCaPath="${MainPath}/GCC64"
# GCCbPath="${MainPath}/GCC32"

KERNELNAME=TheOneMemory

# The name of the Kernel, to name the ZIP
ZIPNAME="$KERNELNAME-Kernel-4-19-KSU"

# Clone Kernulnya Boys
msg "|| Cloning Kernel ||"
git clone --depth=1 --recursive https://$USERNAME:$TOKEN@github.com/Tiktodz/android_kernel_asus_sdm660 kernel

# Clone TeeRBeh Clang
msg "|| Cloning trb_clang ||"
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
export LD=ld.lld
export HOSTLD=ld.lld
export KERNELNAME=TheOneMemory # Change with your localversion name or else.
export KBUILD_BUILD_USER=queen # Change with your own name or else.
IMAGE="${KERNEL_ROOTDIR}"/out/arch/arm64/boot/Image.gz-dtb
CLANG_VER="$("$ClangPath"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
LLD_VER="$("$ClangPath"/bin/ld.lld --version | head -n 1)"
export KBUILD_COMPILER_STRING="$CLANG_VER with $LLD_VER"
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M")
START=$(date +"%s")
# PATH=${ClangPath}/bin:${GCCaPath}/bin:${GCCbPath}/bin:${PATH}
export PATH="${ClangPath}"/bin:${PATH}

# Java
command -v java > /dev/null 2>&1

# Check Kernel Version
KERVER=$(cd $KERNEL_ROOTDIR; make kernelversion)

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"
export BOT_BUILD_URL="https://api.telegram.org/bot$TG_TOKEN/sendDocument"
export STICKER="https://api.telegram.org/bot$TG_TOKEN/sendSticker"
SID="CAACAgUAAxkBAAERkqll1aooPLOdy9vohfuAt0sIAW34PwACWgADZ7RFFph-0udETtQqNAQ"

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

tg_post_build() {
	    curl -F document=@"$1" "$BOT_BUILD_URL" \
	    -F chat_id="$TG_CHAT_ID"  \
	    -F "disable_web_page_preview=true" \
	    -F "parse_mode=Markdown" \
	    -F caption="$2"
}

MAKE="./makeparallel"

# Compile
compile(){
cd ${KERNEL_ROOTDIR}
export HASH_HEAD=$(git rev-parse --short HEAD)
export COMMIT_HEAD=$(git log --oneline -1)
export LD_LIBRARY_PATH="${ClangPath}/lib:${LD_LIBRARY_PATH}"

make ARCH=arm64 asus/X00TD_defconfig O=out 2>&1 | tee -a error.log
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
    HOSTCXX=${ClangPath}/bin/clang++ 2>&1 | tee -a error.log

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
    curl -F document="@$ZIP_FINAL.zip" "$BOT_BUILD_URL" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="✅ Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | 💾 Compiler *${KBUILD_COMPILER_STRING}* | Ⓜ️ MD5 checksum: `md5sum "$ZIP_FINAL.zip" | cut -d' ' -f1`"
}

# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="I'm tired of compiling kernels,And I choose to give up...please give me motivation"
    tg_post_build "error.log" "Compile Error!!"
    exit 1
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
	zip -r9 $ZIPNAME-"$DATE" * -x .git README.md placeholder LICENSE .gitignore zipsigner* *.zip
 
	## Prepare a final zip variable
	ZIP_FINAL="$ZIPNAME-$DATE"

	msg "|| Signing Zip ||"
	tg_post_msg "<code>🔑 Signing Zip file with AOSP keys..</code>"

	curl -sLo zipsigner-3.0.jar https://github.com/Magisk-Modules-Repo/zipsigner/raw/master/bin/zipsigner-3.0-dexed.jar
	java -jar zipsigner-3.0.jar "$ZIP_FINAL".zip "$ZIP_FINAL"-signed.zip
	ZIP_FINAL="$ZIP_FINAL-signed"
	cd ..
}

tg_send_sticker "$SID"
tg_post_msg "🔨 <b>Warning!!</b>%0AStart Building ${KERNELNAME} Kernel ${KERVER}"
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
