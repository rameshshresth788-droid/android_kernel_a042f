#!/bin/bash
# SM-A042F (A042FXXSCEYG2) - stock config + KernelSU-Next, for GitHub Actions
set -e
export ARCH=arm64
export RDIR="$(pwd)"
export KBUILD_BUILD_USER="build"
export KBUILD_BUILD_HOST="a04e"

git submodule update --init --recursive || true

export BUILD_CROSS_COMPILE="${RDIR}/toolchains/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-"
export BUILD_CC="${RDIR}/toolchains/clang-r383902/bin/clang"

if [ ! -x "${BUILD_CC}" ]; then
    echo "ERROR: clang not found at ${BUILD_CC}"; ls -la "${RDIR}/toolchains" || true; exit 1
fi
if [ ! -f "${RDIR}/arch/arm64/configs/a04e_stock_ksu_defconfig" ]; then
    echo "ERROR: arch/arm64/configs/a04e_stock_ksu_defconfig missing"; exit 1
fi

rm -rf "${RDIR}/out" "${RDIR}/build"
mkdir -p "${RDIR}/out" "${RDIR}/build"

export ARGS="
-C ${RDIR} \
O=${RDIR}/out \
-j$(nproc) \
ARCH=arm64 \
CROSS_COMPILE=${BUILD_CROSS_COMPILE} \
CC=${BUILD_CC} \
CLANG_TRIPLE=aarch64-linux-gnu- \
KCFLAGS=-w \
CONFIG_SECTION_MISMATCH_WARN_ONLY=y \
"

make ${ARGS} mrproper

# stock kernel release string so vendor modules' vermagic matches
printf '%s' "-28581296-abA042FXXSCEYG2" > "${RDIR}/.scmversion"

make ${ARGS} a04e_stock_ksu_defconfig
make ${ARGS} olddefconfig

echo "---- config check ----"
grep -E "^CONFIG_(LOCALVERSION|SECURITY_DEFEX|KPROBES|KSU|MODULES|MODVERSIONS)" out/.config || true
make ${ARGS} -s kernelrelease | tee build/kernelrelease.txt

make ${ARGS}

cp out/arch/arm64/boot/Image.gz build/Image.gz
cp out/.config build/final.config
cp out/Module.symvers build/Module.symvers || true
echo "[i] Build finished"
