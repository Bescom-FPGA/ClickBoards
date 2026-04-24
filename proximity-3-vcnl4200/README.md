# MikroE Proximity 3 Click (VCNL4200) Integration for PolarFire SoC Icicle Kit

This directory provides the necessary files to enable the **MikroE Proximity 3 Click** (Vishay VCNL4200, I2C address `0x51`) on the PolarFire SoC Icicle Kit's mikroBUS header.

It is designed to be integrated into a Yocto build environment using the **Microchip `meta-mchp`** layer and the `mpfs-icicle-kit-*` BSP.

## Directory Structure

| Path | Description |
|------|-------------|
| `overlay/mpfs_icicle_vcnl4200.dtso` | Device tree overlay mapping the sensor to `&i2c0` at address `0x51`. |
| `kernel/vcnl4000.cfg` | Kernel configuration fragment enabling `CONFIG_VCNL4000=m`. |
| `patches/*.patch` | Unified diffs for automated integration into the `meta-mchp` layer. Applied with `patch -p1`. |
| `snippets/*` | Code snippets for manual integration if patches do not apply cleanly. |

## Where each bundle item lands in `~/PF_Linux/yocto-dev`

All recipe paths below are under the PolarFire BSP layer:

`BSP = yocto-dev/meta-mchp/meta-mchp-polarfire-soc/meta-mchp-polarfire-soc-bsp`

| ClickBoard path | Action | Target in this project (`PF_Linux`) |
|-----------------|--------|----------------------------------------|
| `overlay/mpfs_icicle_vcnl4200.dtso` | **Copy** (overwrite if updating) | `BSP/recipes-bsp/dt-overlay-mchp/files/mpfs_icicle_vcnl4200.dtso` |
| `kernel/vcnl4000.cfg` | **Copy** | `BSP/recipes-kernel/linux/files/mpfs-icicle-kit-all/vcnl4000.cfg` |
| `snippets/dt-overlay-mchp_git.bbappend.fragment` | **Merge** the `SRC_URI:append:...` line into | `BSP/recipes-bsp/dt-overlay-mchp/dt-overlay-mchp_git.bbappend` |
| `snippets/linux-mchp_6-bbappend-SRC_URI.fragment` | **Merge** `file://vcnl4000.cfg` into `SRC_URI:append:mpfs-icicle-kit-all` in | `BSP/recipes-kernel/linux/linux-mchp_6.%.bbappend` |
| `snippets/boot.cmd.bootm-line.txt` | **Merge** the `bootm start ...` line into | `BSP/recipes-bsp/u-boot/files/mpfs-icicle-kit/boot.cmd` |
| `patches/0001-...` through `0004-...` | **Apply** with `patch -p1` from `PF_Linux` repo root; they edit the same `BSP/...` files above (plus `0002` creates `vcnl4000.cfg`). **Still copy** `overlay/mpfs_icicle_vcnl4200.dtso` into `dt-overlay-mchp/files/` after patches—`0001` does not add the `.dtso` file. |

Paths are the same whether your home is `~/PF_Linux` or elsewhere; only the prefix before `yocto-dev/` changes.

## Hardware Prerequisites

- **I2C Bus Routing:** This overlay assumes the mikroBUS SCL/SDA pins are routed to **MSS I2C0** (`&i2c0`, typically `/dev/i2c-0`) in your Libero FPGA design (`i2c_0_*` ↔ `mBUS_I2C_*`). If your design routes these to a different controller (e.g., fabric CoreI2C `&i2c2`), you must update `mpfs_icicle_vcnl4200.dtso` accordingly.
- **I2C Address:** The default 7-bit address for the VCNL4200 is `0x51`.

## Integration Guide

All paths below assume your Yocto BSP layer is located at:  
`BSP = yocto-dev/meta-mchp/meta-mchp-polarfire-soc/meta-mchp-polarfire-soc-bsp`

You can integrate these files either manually (Method A) or via patches (Method B).

### Method A: Manual Integration

1. **Copy the Device Tree Overlay:**
   ```bash
   cp ClickBoard/proximity-3-vcnl4200/overlay/mpfs_icicle_vcnl4200.dtso \
      "${BSP}/recipes-bsp/dt-overlay-mchp/files/"
   ```

2. **Copy the Kernel Fragment:**
   ```bash
   cp ClickBoard/proximity-3-vcnl4200/kernel/vcnl4000.cfg \
      "${BSP}/recipes-kernel/linux/files/mpfs-icicle-kit-all/"
   ```

3. **Update Recipes:**
   - **`dt-overlay-mchp_git.bbappend`**: Append the `.dtso` file to `SRC_URI` (see `snippets/dt-overlay-mchp_git.bbappend.fragment`).
   - **`linux-mchp_6.%.bbappend`**: Append `file://vcnl4000.cfg \` to the `SRC_URI:append:mpfs-icicle-kit-all` block (see `snippets/linux-mchp_6-bbappend-SRC_URI.fragment`).
   - **`boot.cmd`**: Add `#conf-microchip,mpfs_icicle_vcnl4200.dtbo` to the end of the `bootm start` chain (see `snippets/boot.cmd.bootm-line.txt`).

### Method B: Automated Patching

Run the following commands from the root of your project repository (e.g., `~/PF_Linux`), ensuring the `yocto-dev/` directory is present:

```bash
patch -p1 < ClickBoard/proximity-3-vcnl4200/patches/0001-dt-overlay-mchp-add-vcnl4200-dtso.patch
patch -p1 < ClickBoard/proximity-3-vcnl4200/patches/0002-add-kernel-fragment-vcnl4000.cfg.patch
patch -p1 < ClickBoard/proximity-3-vcnl4200/patches/0003-linux-mchp-bbappend-add-vcnl4000-cfg.patch
patch -p1 < ClickBoard/proximity-3-vcnl4200/patches/0004-u-boot-bootcmd-merge-vcnl4200-overlay.patch
```

**Important:** The patches update the `.bbappend` files but do not create the `.dtso` file. You must manually copy it:
```bash
cp ClickBoard/proximity-3-vcnl4200/overlay/mpfs_icicle_vcnl4200.dtso \
   yocto-dev/meta-mchp/meta-mchp-polarfire-soc/meta-mchp-polarfire-soc-bsp/recipes-bsp/dt-overlay-mchp/files/
```

*(Note: If a patch fails due to upstream changes or a different directory structure, fall back to Method A for that specific component.)*

### Method C: Automated Script

An installation script is provided to automatically apply patches, copy the overlay, and rebuild the image using `bitbake`.

```bash
cd ~/PF_Linux/ClickBoard/proximity-3-vcnl4200
./install_and_build.sh
```

The script will:
1. Apply the patches (`.bbappend` and `boot.cmd` modifications).
2. Copy `mpfs_icicle_vcnl4200.dtso` to the correct BSP directory.
3. Source the Yocto environment (`source openembedded-core/oe-init-build-env build`).
4. Run `bitbake -c cleansstate` for the modified recipes and build `mchp-base-image`.

## Building the Image

Rebuild the affected components and the final image:

```bash
bitbake dt-overlay-mchp -c cleansstate
bitbake linux-mchp -c cleansstate
bitbake u-boot -c cleansstate
bitbake mchp-base-image
```

## Verification

After booting the new image on the target board, verify the sensor is detected and the driver is bound:

```bash
# Check available I2C buses
i2cdetect -l

# Scan I2C bus 0 (assuming MSS I2C0)
i2cdetect -y 0

# Verify driver binding
ls -l /sys/bus/i2c/devices/0-0051/driver
```

A successful setup will show `UU` at address `0x51` in the `i2cdetect` output, and the `driver` symlink will point to `vcnl4000`.