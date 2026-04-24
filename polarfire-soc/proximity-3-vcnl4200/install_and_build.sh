#!/bin/bash

set -e

# Get the absolute path to the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The root of the PF_Linux project (ClickBoard/polarfire-soc/<bundle> → 3 levels up)
PROJECT_ROOT="$(realpath "${SCRIPT_DIR}/../../..")"
YOCTO_DIR="${PROJECT_ROOT}/yocto-dev"
BSP_DIR="${YOCTO_DIR}/meta-mchp/meta-mchp-polarfire-soc/meta-mchp-polarfire-soc-bsp"

echo "=========================================================="
echo " MikroE Proximity 3 Click (VCNL4200) Integration Script"
echo "=========================================================="

if [ ! -d "${YOCTO_DIR}" ]; then
    echo "Error: Could not find yocto-dev directory at ${YOCTO_DIR}"
    exit 1
fi

echo "[1/4] Applying patches to the meta-mchp layer..."
cd "${PROJECT_ROOT}"

for patch_file in "${SCRIPT_DIR}/patches/"*.patch; do
    patch_name=$(basename "$patch_file")
    echo -n "  -> Checking ${patch_name}... "
    
    # Check if patch is already applied
    if patch -p1 --dry-run --reverse --force < "$patch_file" >/dev/null 2>&1; then
        echo "Already applied (Skipping)."
    # Check if patch can be applied cleanly
    elif patch -p1 --dry-run --forward < "$patch_file" >/dev/null 2>&1; then
        patch -p1 --forward < "$patch_file" >/dev/null
        echo "Applied successfully."
    else
        echo "FAILED!"
        echo "Error: Patch does not apply cleanly. You may need to integrate manually (See README.md Method B)."
        exit 1
    fi
done

echo ""
echo "[2/4] Copying the device tree overlay (.dtso)..."
mkdir -p "${BSP_DIR}/recipes-bsp/dt-overlay-mchp/files"
cp "${SCRIPT_DIR}/overlay/mpfs_icicle_vcnl4200.dtso" "${BSP_DIR}/recipes-bsp/dt-overlay-mchp/files/"
echo "  -> Copied mpfs_icicle_vcnl4200.dtso to dt-overlay-mchp/files/"

echo ""
echo "[3/4] Initializing Yocto build environment..."
cd "${YOCTO_DIR}"

if [ ! -f "openembedded-core/oe-init-build-env" ]; then
    echo "Error: oe-init-build-env not found in ${YOCTO_DIR}/openembedded-core"
    exit 1
fi

# Source the environment (assuming 'build' is the default build directory)
source openembedded-core/oe-init-build-env build >/dev/null
echo "  -> Sourced oe-init-build-env"

# Allow bitbake to run as root if needed
touch conf/sanity.conf

echo ""
echo "[4/4] Running bitbake to rebuild affected components and the image..."
echo "  -> This may take some time depending on your system."
echo ""

# Clean states for modified recipes to ensure they are rebuilt
echo ">>> Cleaning sstate for modified recipes..."
bitbake dt-overlay-mchp -c cleansstate
bitbake linux-mchp -c cleansstate
bitbake u-boot -c cleansstate

# Build the final image
echo ">>> Building mchp-base-image..."
bitbake mchp-base-image

echo ""
echo "=========================================================="
echo " Integration and Build Complete!"
echo "=========================================================="
echo "Please flash the new image/overlays to your board and verify."
