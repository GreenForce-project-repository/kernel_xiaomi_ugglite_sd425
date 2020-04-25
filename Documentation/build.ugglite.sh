#!/usr/bin/env bash
# Circle CI/CD - Simple kernel build script
# Copyright (C) 2019 Raphielscape LLC (@raphielscape)
# Copyright (C) 2019 Dicky Herlambang (@Nicklas373)
# Copyright (C) 2020 Muhammad Fadlyas (@fadlyas07)

export ARCH=arm64
export TEMP=$(pwd)/temp
export TELEGRAM_ID=$chat_id
export TELEGRAM_TOKEN=$token
export pack=$(pwd)/anykernel-3
export product_name=GreenForce
export device="Xiaomi Redmi Note 5A"
export KBUILD_BUILD_HOST=$(whoami)
export KBUILD_BUILD_USER=Mhmmdfadlyas
export parse_branch=$(git rev-parse --abbrev-ref HEAD)
export kernel_img=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
build_start=$(date +"%s")

mkdir $(pwd)/temp
echo "GCC 4.9.x 20150123 ARCH64 & ARM32 already in /root/ directory"
git clone --depth=1 --single-branch https://github.com/fabianonline/telegram.sh telegram
git clone --depth=1 --single-branch https://github.com/fadlyas07/anykernel-3

TELEGRAM=telegram/telegram
tg_channelcast() {
    "$TELEGRAM" -c "$TELEGRAM_ID" -H \
	"$(
		for POST in "$@"; do
			echo "$POST"
		done
	)"
}

date1=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
make ARCH=arm64 O=out ugglite_defconfig && \
PATH=/root/gcc/bin:/root/gcc32/bin:$PATH \
make -j$(nproc --all) O=out \
		      ARCH=arm64 \
		      CROSS_COMPILE=aarch64-linux-android- \
		      CROSS_COMPILE_ARM32=arm-linux-androideabi- 2>&1| tee build_kernel.log
mv *.log $TEMP
if [[ ! -f "$kernel_img" ]]; then
	curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
	tg_channelcast "$product_name $device Build Failed!"
	exit 1
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
mv $kernel_img $pack/zImage
cd $pack && zip -r9q $product_name-ugglite-$date1.zip * -x .git README.md LICENCE $(echo *.zip)
cd ..
build_end=$(date +"%s")
build_diff=$(($build_end - $build_start))
kernel_ver=$(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)
toolchain_ver=$(cat $(pwd)/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
tg_channelcast "⚠️ <i>Warning: New build is available!</i> working on <b>$parse_branch</b> in <b>Linux $kernel_ver</b> using <b>$toolchain_ver</b> for <b>$device</b> at commit <b>$(git log --pretty=format:'%s' -1)</b>. Build complete in $(($build_diff / 60)) minutes and $(($build_diff % 60)) seconds."
curl -F document=@$(echo $pack/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
