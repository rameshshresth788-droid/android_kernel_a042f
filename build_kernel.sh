#!/bin/bash
set -euo pipefail

export ARCH=arm64
export RDIR="$(pwd)"
export KBUILD_BUILD_USER="Ramesh"
export KBUILD_BUILD_HOST="A04E"

OUT="${RDIR}/out"
BUILD="${RDIR}/build"

CROSS="${RDIR}/toolchains/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-"
CLANG="${RDIR}/toolchains/clang-r383902/bin/clang"

echo "[1/6] Checking toolchains..."

test -x "${CLANG}" || { echo "ERROR: Clang not found"; exit 1; }
test -x "${CROSS}gcc" || { echo "ERROR: GCC cross compiler not found"; exit 1; }

echo "[2/6] Checking KernelSU-Next..."

git submodule update --init --recursive
test -f drivers/kernelsu/Kconfig || { echo "ERROR: KernelSU source missing"; exit 1; }

echo "[3/6] Preparing output..."

rm -rf "${OUT}" "${BUILD}"
mkdir -p "${OUT}" "${BUILD}"

echo "[4/6] Creating kernel configuration..."

make -C "${RDIR}" O="${OUT}" ARCH=arm64 a04e_defconfig

"${RDIR}/scripts/kconfig/merge_config.sh" \
    -m -O "${OUT}" \
    "${OUT}/.config" \
    "${RDIR}/arch/arm64/configs/custom.config"

make -C "${RDIR}" O="${OUT}" ARCH=arm64 olddefconfig

echo "[5/6] Compiling kernel..."

make -C "${RDIR}" O="${OUT}" \
    ARCH=arm64 \
    CROSS_COMPILE="${CROSS}" \
    CC="${CLANG}" \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    KCFLAGS=-w \
    CONFIG_SECTION_MISMATCH_WARN_ONLY=y \
    -j"$(nproc)" Image.gz

echo "[6/6] Saving kernel artifact..."

test -s "${OUT}/arch/arm64/boot/Image.gz"

cp "${OUT}/arch/arm64/boot/Image.gz" "${BUILD}/Image.gz"

echo "Kernel build completed."
ls -lh "${BUILD}/Image.gz"
