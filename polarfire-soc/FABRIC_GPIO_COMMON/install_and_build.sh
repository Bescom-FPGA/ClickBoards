#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(realpath "${SCRIPT_DIR}/../../..")"
YOCTO_DIR="${PROJECT_ROOT}/yocto-dev"
BSP_DIR="${YOCTO_DIR}/meta-mchp/meta-mchp-polarfire-soc/meta-mchp-polarfire-soc-bsp"

echo "=========================================================="
echo " Fabric GPIO Common Overlay Integration Script"
echo "=========================================================="

if [ ! -d "${YOCTO_DIR}" ]; then
    echo "Error: Could not find yocto-dev directory at ${YOCTO_DIR}"
    exit 1
fi

echo "[1/4] Applying patches..."
cd "${PROJECT_ROOT}"
for patch_file in "${SCRIPT_DIR}/patches/"*.patch; do
    patch_name=$(basename "$patch_file")
    echo -n "  -> Checking ${patch_name}... "
    if patch -p1 --dry-run --reverse --force < "$patch_file" >/dev/null 2>&1; then
        echo "Already applied (Skipping)."
    elif patch -p1 --dry-run --forward < "$patch_file" >/dev/null 2>&1; then
        patch -p1 --forward < "$patch_file" >/dev/null
        echo "Applied successfully."
    else
        echo "FAILED!"
        exit 1
    fi
done

# boot.cmd: cannot rely on a unified patch — Thumbstick/OLED workflows may already
# chain cpu_opp+fabric+board. Insert fabric after cpu_opp only if missing.
BOOT_CMD="${BSP_DIR}/recipes-bsp/u-boot/files/mpfs-icicle-kit/boot.cmd"
FAB_FRAG="#conf-microchip,mpfs_icicle_fabric_gpio.dtbo"
if [ -f "${BOOT_CMD}" ] && grep -qE '^bootm start ' "${BOOT_CMD}"; then
	if ! grep -qF "${FAB_FRAG}" "${BOOT_CMD}"; then
		sed -i 's|\(#conf-microchip,mpfs_icicle_cpu_opp\.dtbo\)|\1'"${FAB_FRAG}"'|' "${BOOT_CMD}"
		echo "  -> boot.cmd: appended ${FAB_FRAG} after cpu_opp."
	else
		echo "  -> boot.cmd: ${FAB_FRAG} already present (unchanged)."
	fi
fi

echo "[2/4] Copying mpfs_icicle_fabric_gpio.dtso..."
mkdir -p "${BSP_DIR}/recipes-bsp/dt-overlay-mchp/files"
cp "${SCRIPT_DIR}/overlay/mpfs_icicle_fabric_gpio.dtso" "${BSP_DIR}/recipes-bsp/dt-overlay-mchp/files/"

echo "[3/4] Initializing Yocto environment..."
cd "${YOCTO_DIR}"
source openembedded-core/oe-init-build-env build >/dev/null
touch conf/sanity.conf

echo "[4/4] Rebuilding image..."
bitbake dt-overlay-mchp -c cleansstate
bitbake u-boot-mchp -c cleansstate
bitbake mchp-base-image

echo "Done."
