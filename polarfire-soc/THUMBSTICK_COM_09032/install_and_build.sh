#!/bin/bash
#
# MikroE Thumbstick Click (COM-09032 / MCP3204) — run ../FABRIC_GPIO_COMMON first,
# then this script. All steps are in this file (no shared helper): reset → patch
# → boot.cmd → copy .dtso → bitbake.
# Set SKIP_CLICK_BSP_RESET=1 to skip the pre-step that clears *other* Click state.
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(realpath "${SCRIPT_DIR}/../../..")"
YOCTO_DIR="${PROJECT_ROOT}/yocto-dev"
BSP_DIR="${YOCTO_DIR}/meta-mchp/meta-mchp-polarfire-soc/meta-mchp-polarfire-soc-bsp"
BOOT_CMD="${BSP_DIR}/recipes-bsp/u-boot/files/mpfs-icicle-kit/boot.cmd"
DT_OVL_BB="${BSP_DIR}/recipes-bsp/dt-overlay-mchp/dt-overlay-mchp_git.bbappend"
KERNEL_FR_DIR="${BSP_DIR}/recipes-kernel/linux/files/mpfs-icicle-kit-all"
LINUX_MCHP_BB="${BSP_DIR}/recipes-kernel/linux/linux-mchp_6.%.bbappend"
DT_OVL_FILES="${BSP_DIR}/recipes-bsp/dt-overlay-mchp/files"
THIS_FIT_NAME="mpfs_icicle_thumbstick"

echo "=========================================================="
echo " MikroE Thumbstick Click (COM-09032 / MCP3204) Integration"
echo "=========================================================="

if [ ! -d "${YOCTO_DIR}" ]; then
    echo "Error: Could not find yocto-dev directory at ${YOCTO_DIR}"
    exit 1
fi

# ---------------------------------------------------------------------------
# Pre: remove other Click bundles' kernel / dt-overlay / U-Boot / file copies.
# Does not revert FABRIC_GPIO_COMMON. Skip with SKIP_CLICK_BSP_RESET=1.
# ---------------------------------------------------------------------------
if [ -z "${SKIP_CLICK_BSP_RESET}" ]; then
    echo ""
    echo "---- Pre: reset other Clicks (FABRIC + vendor tree kept) ----"
    # Do NOT use "patch -R" here: GNU patch asks y/n on /dev/tty when the tree
    # does not match, which breaks non-interactive runs and leaves .rej files.
    echo "  Dropping other boards' kernel fragment lines in linux-mchp bbappend + cfg files…"
    rm -f \
        "${KERNEL_FR_DIR}/mcp320x.cfg" \
        "${KERNEL_FR_DIR}/spidev.cfg" \
        "${KERNEL_FR_DIR}/ssd1351.cfg" 2>/dev/null || true
    rm -f "${LINUX_MCHP_BB}.rej" 2>/dev/null || true
    if [ -f "${LINUX_MCHP_BB}" ] && [ -x /usr/bin/python3 ]; then
        /usr/bin/python3 - "${LINUX_MCHP_BB}" <<'PY'
import re, sys
path = sys.argv[1]
with open(path) as fp:
    lines = fp.readlines()
drop = re.compile(r"file://(mcp320x|spidev|ssd1351)\.cfg")
out = [ln for ln in lines if not drop.search(ln)]
with open(path, "w") as fp:
    fp.writelines(out)
PY
    fi

    echo "  Normalising dt-overlay-mchp_git.bbappend head to fabric-only…"
    if [ -f "${DT_OVL_BB}" ] && [ -x /usr/bin/python3 ]; then
        /usr/bin/python3 - "${DT_OVL_BB}" <<'PY'
import re, sys
f = sys.argv[1]
with open(f) as fp:
    lines = fp.readlines()
out, i, n = [], 0, len(lines)
while i < n:
    if re.match(r"^inherit devicetree\s*$", lines[i]):
        out.append(lines[i])
        i += 1
        out.append("\n")
        out.append('FILESEXTRAPATHS:prepend := "${THISDIR}/files:"\n')
        out.append(
            'SRC_URI:append:mpfs-icicle-kit-all = " file://mpfs_icicle_fabric_gpio.dtso;subdir=git/mpfs_icicle"\n'
        )
        out.append("\n")
        while i < n and not re.match(r"^\s*S\s*=\s*", lines[i]):
            i += 1
        if i < n:
            out.append(lines[i])
            i += 1
        continue
    out.append(lines[i])
    i += 1
with open(f, "w") as fp:
    fp.writelines(out)
PY
    else
        echo "  (skip: no python3 or missing ${DT_OVL_BB})"
    fi

    echo "  boot.cmd: strip other boards' FIT; ensure fabric is present…"
    if [ -f "${BOOT_CMD}" ]; then
        for t in mpfs_icicle_thumbstick mpfs_icicle_oled_c mpfs_icicle_bargraph; do
            sed -i "s|#conf-microchip,${t}\.dtbo||g" "${BOOT_CMD}" 2>/dev/null || true
        done
    fi
    if [ -f "${BOOT_CMD}" ] && ! grep -qF "#conf-microchip,mpfs_icicle_fabric_gpio.dtbo" "${BOOT_CMD}" \
        && grep -qE '^bootm start ' "${BOOT_CMD}"; then
        sed -i "/^bootm start /s|\$|#conf-microchip,mpfs_icicle_fabric_gpio.dtbo|" "${BOOT_CMD}"
    fi
    echo "  Removing other boards' .dtso (not fabric) from dt-overlay files/…"
    if [ -d "${DT_OVL_FILES}" ]; then
        rm -f \
            "${DT_OVL_FILES}/mpfs_icicle_thumbstick.dtso" \
            "${DT_OVL_FILES}/mpfs_icicle_oled_c.dtso" \
            "${DT_OVL_FILES}/mpfs_icicle_bargraph.dtso" 2>/dev/null || true
    fi
    echo "---- Pre: done ----"
    echo ""
fi

echo "[1/4] Applying patches to the meta-mchp layer…"
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
        echo "Error: Patch does not apply cleanly. You may need to integrate manually (see README.md)."
        exit 1
    fi
done

echo -n "  -> U-Boot boot.cmd: append ${THIS_FIT_NAME} to bootm start line… "
FIT_FRAG="#conf-microchip,${THIS_FIT_NAME}.dtbo"
if [ -f "${BOOT_CMD}" ] && ! grep -qF "${FIT_FRAG}" "${BOOT_CMD}" && grep -qE '^bootm start ' "${BOOT_CMD}"; then
    sed -i "/^bootm start /s|\$|${FIT_FRAG}|" "${BOOT_CMD}"
    echo "ok (${FIT_FRAG})."
elif [ -f "${BOOT_CMD}" ] && grep -qF "${FIT_FRAG}" "${BOOT_CMD}"; then
    echo "already present."
else
    echo "skip (no boot.cmd or no bootm start line)."
fi

echo ""
echo "[2/4] Copying the device tree overlay (.dtso)…"
mkdir -p "${BSP_DIR}/recipes-bsp/dt-overlay-mchp/files"
cp "${SCRIPT_DIR}/overlay/mpfs_icicle_thumbstick.dtso" "${BSP_DIR}/recipes-bsp/dt-overlay-mchp/files/"
COMMON_DIR="${SCRIPT_DIR}/../FABRIC_GPIO_COMMON/overlay"
if [ -f "${COMMON_DIR}/mpfs_icicle_fabric_gpio.dtso" ]; then
    cp "${COMMON_DIR}/mpfs_icicle_fabric_gpio.dtso" "${BSP_DIR}/recipes-bsp/dt-overlay-mchp/files/"
    echo "  -> Copied mpfs_icicle_thumbstick.dtso and mpfs_icicle_fabric_gpio.dtso"
else
    echo "  -> Copied mpfs_icicle_thumbstick.dtso"
    echo "  -> WARNING: ${COMMON_DIR}/mpfs_icicle_fabric_gpio.dtso not found."
    echo "     Build may fail if &fabric_gpio is referenced without the common overlay."
fi

echo ""
echo "[3/4] Initializing Yocto build environment…"
cd "${YOCTO_DIR}"

if [ ! -f "openembedded-core/oe-init-build-env" ]; then
    echo "Error: oe-init-build-env not found in ${YOCTO_DIR}/openembedded-core"
    exit 1
fi

source openembedded-core/oe-init-build-env build >/dev/null
echo "  -> Sourced oe-init-build-env"

touch conf/sanity.conf

echo ""
echo "[4/4] Running bitbake to rebuild affected components and the image…"
echo ""

echo ">>> Cleaning sstate for modified recipes…"
bitbake dt-overlay-mchp -c cleansstate
bitbake linux-mchp -c cleansstate
bitbake u-boot-mchp -c cleansstate

echo ">>> Building mchp-base-image…"
bitbake mchp-base-image

echo ""
echo "=========================================================="
echo " Integration and Build Complete!"
echo "=========================================================="
echo "Please flash the new image/overlays to your board and verify."
