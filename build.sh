#!/usr/bin/env bash
#
# Copyright (C) 2023-2024 Kneba <abenkenary3@gmail.com>
#

#
# Function to show an informational message
#

msg() {
	echo
    echo -e "\e[1;35m$*\e[0m"
    echo
}

err() {
    echo -e "\e[1;41m$*\e[0m"
}

cdir() {
	cd "$1" 2>/dev/null || \
		err "The directory $1 doesn't exists !"
}

# Main
MainPath="$(pwd)"
MainClangPath="${MainPath}/clang"
ClangPath="${MainClangPath}"
MainGCCaPath="${MainPath}/GCC64"
MainGCCbPath="${MainPath}/GCC32"
GCCaPath="${MainGCCaPath}"
GCCbPath="${MainGCCbPath}"

# Identity
ARCH=arm64
CODENAME=Hayzel
DEFCONFIG=X00TD_defconfig
KERNELNAME=TheOneMemory
VARIANT=HMP
VERSION=CLO

# Show manufacturer info
MANUFACTURERINFO="ASUSTek Computer Inc."

# Clone Kernel Source
msg "|| Cloning Kernel Source ||"
git clone --depth=1 --recursive https://$USERNAME:$TOKEN@github.com/Tiktodz/android_kernel_asus_sdm636 kernel

# Clone Snapdragon Clang
ClangPath=${MainClangPath}
[[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
mkdir $ClangPath
rm -rf $ClangPath/*

msg "|| Cloning snapdragon clang ||"
git clone --depth=1 https://gitlab.com/VoidUI/snapdragon-clang.git $ClangPath

# Clone GCC
mkdir $GCCaPath
mkdir $GCCbPath

msg "|| Cloning GCC aarch64 ||"
git clone --depth=1 https://github.com/Kneba/aarch64-linux-android-4.9 $GCCaPath
msg "|| Cloning GCC arm ||"
git clone --depth=1 https://github.com/Kneba/arm-linux-androideabi-4.9 $GCCbPath

# Prepared
KERNEL_ROOTDIR=$(pwd)/kernel # IMPORTANT ! Fill with your kernel source root directory.
export KBUILD_BUILD_USER=queen # Change with your own name or else.
IMAGE=$(pwd)/kernel/out/arch/arm64/boot/Image.gz-dtb
CLANG_VER="Snapdragon clang version 16.1.0"
#LLD_VER="$("$ClangPath"/bin/ld.lld --version | head -n 1)"
export KBUILD_COMPILER_STRING="$CLANG_VER X GCC 4.9.x"
ClangMoreStrings="AR=llvm-ar NM=llvm-nm AS=llvm-as STRIP=llvm-strip OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump READELF=llvm-readelf HOSTAR=llvm-ar HOSTAS=llvm-as LD_LIBRARY_PATH=$ClangPath/lib LD=ld.lld HOSTLD=ld.lld"
export TZ=Asia/Jakarta
DATE=$(date +"%Y%m%d"-%H%M)
START=$(date +"%s")

# Java
command -v java > /dev/null 2>&1

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

# Telegram messaging
tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
    -d "disable_web_page_preview=true" \
    -d "parse_mode=html" \
    -d text="$1"
}

####------------------------------o-O-o------------------------------####

# Compiler
compile(){
cd ${KERNEL_ROOTDIR}
msg "|| Cooking kernel. . . ||"
export HASH_HEAD=$(git rev-parse --short HEAD)
export COMMIT_HEAD=$(git log --oneline -1)
export LLVM=1
export LLVM_IAS=1

make -j$(nproc) O=out $DEFCONFIG
make -j$(nproc) O=out \
        ARCH=$ARCH \
        SUBARCH=$ARCH \
        PATH=$ClangPath/bin:$GCCaPath/bin:$GCCbPath/bin:/usr/bin:${PATH} \
        CC=clang \
        CROSS_COMPILE=aarch64-linux-android- \
        CROSS_COMPILE_ARM32=arm-linux-androideabi- \
        CLANG_TRIPLE=aarch64-linux-gnu- \
        HOSTCC=gcc \
        HOSTCXX=g++ ${ClangMoreStrings}

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi

   msg "|| Cloning AnyKernel ||"
   git clone https://github.com/Tiktodz/AnyKernel3 -b hmp-old AnyKernel
   cp $IMAGE AnyKernel
}

####------------------------------o-O-o------------------------------####

# Push kernel to telegram
function push() {
    cd AnyKernel
    curl -F document="@$ZIP_FINAL.zip" "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="🔐<b>Build Done</b>
        - <code>$((DIFF / 60)) minute(s) $((DIFF % 60)) second(s)... </code>

        <b>📅 Build Date: </b>
        -<code>$DATE</code>

         <b>💿 Compiler: </b>
        -<code>$KBUILD_COMPILER_STRING</code>

        <b>📱 Device: </b>
        -<code>$DEVICE_CODENAME($MANUFACTURERINFO)</code>

        <b>🆑 Changelog: </b>
        - <code>$COMMIT_HEAD</code>
        <b></b>
        #$KERNELNAME #$CODENAME #$VARIANT"
}

####------------------------------o-O-o------------------------------####

# Find Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="❌ Tetap menyerah...Pasti bisa!!!"
    exit 1
}

####------------------------------o-O-o------------------------------####

# Zipping
function zipping() {
    cd AnyKernel || exit 1
	cp -af $KERNEL_ROOTDIR/init.$CODENAME.Spectrum.rc spectrum/init.spectrum.rc && sed -i "s/persist.spectrum.kernel.*/persist.spectrum.kernel TheOneMemory/g" spectrum/init.spectrum.rc
	cp -af $KERNEL_ROOTDIR/changelog META-INF/com/google/android/aroma/changelog.txt
	cp -af anykernel-real.sh anykernel.sh
	sed -i "s/kernel.string=.*/kernel.string=$KERNELNAME/g" anykernel.sh
	sed -i "s/kernel.type=.*/kernel.type=$VARIANT/g" anykernel.sh
	sed -i "s/kernel.for=.*/kernel.for=$CODENAME/g" anykernel.sh
	sed -i "s/kernel.compiler=.*/kernel.compiler=$KBUILD_COMPILER_STRING/g" anykernel.sh
	sed -i "s/kernel.made=.*/kernel.made=dotkit @fakedotkit/g" anykernel.sh
	sed -i "s/kernel.version=.*/kernel.version=$VERSION/g" anykernel.sh
	sed -i "s/message.word=.*/message.word=Appreciate your efforts for choosing TheOneMemory kernel./g" anykernel.sh
	sed -i "s/build.date=.*/build.date=$DATE/g" anykernel.sh
	sed -i "s/build.type=.*/build.type=$VERSION/g" anykernel.sh
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
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push

####------------------------------o-O-o------------------------------####
