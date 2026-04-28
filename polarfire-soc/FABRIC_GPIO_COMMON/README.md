# Fabric GPIO Common Overlay — PolarFire SoC Icicle Kit

This directory provides a **shared device tree overlay** that instantiates **`fabric_gpio`** (`microchip,coregpio-rtl-v3`) so other Click bundles (e.g. OLED, Thumbstick) can use **`&fabric_gpio`** in their overlays.

It is integrated with **Microchip `meta-mchp`** and the **`mpfs-icicle-kit-*`** BSP.

## Directory Structure

| Path | Description |
|------|-------------|
| `overlay/mpfs_icicle_fabric_gpio.dtso` | Adds `fabric_gpio: gpio@…` (set `reg`, `ngpios`, and clock to match Libero). |
| `patches/0001-*.patch` | Adds the `.dtso` to `dt-overlay-mchp` `SRC_URI`. |
| `snippets/*` | Manual merge hints if the patch does not apply. |
| `install_and_build.sh` | Applies patches, inserts the fabric FIT fragment into **`boot.cmd`** when missing, copies the `.dtso`, runs `bitbake`. |
| `MPFS_ICICLE_KIT_BASE_DESIGN_THUMBSTICK_CLICK.job` | Optional Libero **FlashPro programming job** for the FPGA image that pairs with this overlay (see below). |

### Libero FPGA programming file (`*.job`)

When present, **`MPFS_ICICLE_KIT_BASE_DESIGN_THUMBSTICK_CLICK.job`** is the exported programming job for a Libero design aligned with **`mpfs_icicle_fabric_gpio.dtso`**:

- **Fabric CoreGPIO** (`microchip,coregpio-rtl-v3`) on the FIC3 APB window used in the overlay (`reg` / `ngpios` / `clocks` must still match your build).
- mikroBUS **`mBUS_PWM`** and **`mBUS_INT`** brought into that CoreGPIO block (GPIO mapping as implemented in Libero — used by Thumbstick / OLED overlays for DC and INT paths).

Flash this **`.job`** to the Icicle FPGA (e.g. FlashPro) **in addition** to deploying the Linux image and DT overlays; software alone cannot replace the fabric routing.

**Git / cleanup:** Delete any files named like `*.job:Zone.Identifier` (or `*:Zone.Identifier`). Those are Windows “Mark of the Web” sidecars from downloading files, not Libero output — they are safe to remove and should not be committed.

## Where each bundle item lands in `~/PF_Linux/yocto-dev`

`BSP = yocto-dev/meta-mchp/meta-mchp-polarfire-soc/meta-mchp-polarfire-soc-bsp`

| Bundle path | Action | Target in `PF_Linux` |
|-------------|--------|----------------------|
| `overlay/mpfs_icicle_fabric_gpio.dtso` | **Copy** | `BSP/recipes-bsp/dt-overlay-mchp/files/` |
| `snippets/dt-overlay-mchp_git.bbappend.fragment` | **Merge** | `BSP/recipes-bsp/dt-overlay-mchp/dt-overlay-mchp_git.bbappend` |
| `snippets/boot.cmd.bootm-line.txt` | **Merge** FIT token `#conf-microchip,mpfs_icicle_fabric_gpio.dtbo` | `BSP/recipes-bsp/u-boot/files/mpfs-icicle-kit/boot.cmd` |
| `patches/0001-*.patch` | **Apply** with `patch -p1` | Updates the same BSP files; **still copy** the `.dtso` afterward if using Method C. |

## Hardware Prerequisites

Edit **`overlay/mpfs_icicle_fabric_gpio.dtso`** before building:

- **`reg`**: APB base address of CoreGPIO in your Libero / FIC map.
- **`ngpios`**: Width of the CoreGPIO instance.
- **`clocks`**: Must match the fabric clock tree (same style as other FIC3 peripherals in `mpfs-icicle-kit-fabric.dtsi`).

## Integration Guide

### Method A: Automated script

```bash
cd ~/PF_Linux/tmp_ClickBoard/polarfire-soc/FABRIC_GPIO_COMMON
chmod +x install_and_build.sh
./install_and_build.sh
```

This applies **`0001`**, updates **`boot.cmd`** when the fabric FIT entry is absent, copies **`mpfs_icicle_fabric_gpio.dtso`**, and builds **`mchp-base-image`** (cleans **`dt-overlay-mchp`** and **`u-boot-mchp`**; does not rebuild **`linux-mchp`**).

### Method B: Manual integration

Copy **`overlay/mpfs_icicle_fabric_gpio.dtso`** to `BSP/recipes-bsp/dt-overlay-mchp/files/`, merge **`snippets/dt-overlay-mchp_git.bbappend.fragment`** and **`snippets/boot.cmd.bootm-line.txt`**, then **Building the Image**.

### Method C: Patches only

From the **`PF_Linux` repository root**:

```bash
patch -p1 < tmp_ClickBoard/polarfire-soc/FABRIC_GPIO_COMMON/patches/0001-dt-overlay-mchp-add-fabric-gpio-dtso.patch
```

Then copy **`tmp_ClickBoard/polarfire-soc/FABRIC_GPIO_COMMON/overlay/mpfs_icicle_fabric_gpio.dtso`** into `BSP/recipes-bsp/dt-overlay-mchp/files/` and merge **`boot.cmd`** as in **Method B**.

## Building the Image

After **Method B** or **C**:

```bash
cd ~/PF_Linux/yocto-dev
source openembedded-core/oe-init-build-env build
bitbake dt-overlay-mchp -c cleansstate
bitbake u-boot-mchp -c cleansstate
bitbake mchp-base-image
```

## Verification

Confirm the overlay is packaged and the FIT chain includes **`mpfs_icicle_fabric_gpio.dtbo`** (e.g. inspect `/boot` on the target and the device tree under `/proc/device-tree` after boot).
