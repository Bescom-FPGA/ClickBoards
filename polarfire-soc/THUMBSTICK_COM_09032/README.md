# MikroE Thumbstick Click (MIKROE-1627 / MCP3204) Integration for PolarFire SoC Icicle Kit

This directory provides the files needed to enable the **MikroE Thumbstick Click** (dual-axis joystick with pushbutton, **MCP3204** ADC on SPI) on the PolarFire SoC Icicle Kit mikroBUS header.

It targets a Yocto tree with **Microchip `meta-mchp`** and the **`mpfs-icicle-kit-*`** BSP. The pushbutton path uses **Fabric CoreGPIO** plus **`gpio-keys-polled`**; this bundle copies **`mpfs_icicle_fabric_gpio.dtso`** from [`../FABRIC_GPIO_COMMON/`](../FABRIC_GPIO_COMMON/README.md).

Reference: [Thumbstick Click (MikroE)](https://www.mikroe.com/thumbstick-click)

## Directory Structure

| Path | Description |
|------|-------------|
| `overlay/mpfs_icicle_thumbstick.dtso` | Enables `&spi1` + `microchip,mcp3204`; adds **`gpio-keys-polled`** for the pushbutton. |
| `kernel/mcp320x.cfg` | Kernel fragment: MCP320x, gpio-keys / polled keys, **`CONFIG_INPUT_EVDEV=m`** (`/dev/input/event*`). |
| `patches/*.patch` | Unified diffs applied with `patch -p1` from the repository root (`PF_Linux`). |
| `snippets/*` | Manual merge hints if a patch fails. |
| `install_and_build.sh` | Applies patches, merges `boot.cmd`, copies `.dtso` files (thumbstick + fabric gpio), runs `bitbake`. |

## Where each bundle item lands in `~/PF_Linux/yocto-dev`

All recipe paths below are under the PolarFire BSP layer:

`BSP = yocto-dev/meta-mchp/meta-mchp-polarfire-soc/meta-mchp-polarfire-soc-bsp`

| Bundle path | Action | Target in `PF_Linux` |
|-------------|--------|----------------------|
| `overlay/mpfs_icicle_thumbstick.dtso` | **Copy** | `BSP/recipes-bsp/dt-overlay-mchp/files/` |
| `../FABRIC_GPIO_COMMON/overlay/mpfs_icicle_fabric_gpio.dtso` | **Copy** (by `install_and_build.sh`) | same `dt-overlay-mchp/files/` |
| `kernel/mcp320x.cfg` | **Copy** (via patches `0002`–`0005`) | `BSP/recipes-kernel/linux/files/mpfs-icicle-kit-all/mcp320x.cfg` |
| `snippets/dt-overlay-mchp_git.bbappend.fragment` | **Merge** `SRC_URI` | `BSP/recipes-bsp/dt-overlay-mchp/dt-overlay-mchp_git.bbappend` |
| `snippets/linux-mchp_6-bbappend-SRC_URI.fragment` | **Merge** kernel fragment into `SRC_URI` | `BSP/recipes-kernel/linux/linux-mchp_6.%.bbappend` |
| `snippets/boot.cmd.bootm-line.txt` | **Merge** FIT chain | `BSP/recipes-bsp/u-boot/files/mpfs-icicle-kit/boot.cmd` |
| `patches/0001`–`0005` | **Apply** with `patch -p1` | Same BSP files as above; still **copy** both `.dtso` files after patches if you use Method C. |

Paths are the same whether your checkout is `~/PF_Linux/tmp_ClickBoard` or `~/PF_Linux/ClickBoard`; only the prefix before `polarfire-soc/` changes.

## Hardware Prerequisites

- **SPI:** mikroBUS SPI routed to **MSS SPI1** (`&spi1`).
- **Pushbutton (INT):** mikroBUS INT wired to your **Fabric CoreGPIO** bit; set `gpios = <&fabric_gpio N …>;` in `mpfs_icicle_thumbstick.dtso` to match Libero.
- **Fabric GPIO overlay:** Edit `../FABRIC_GPIO_COMMON/overlay/mpfs_icicle_fabric_gpio.dtso` (`reg`, `ngpios`, clock) for your CoreGPIO block.

## Integration Guide

**BSP** below means `yocto-dev/meta-mchp/meta-mchp-polarfire-soc/meta-mchp-polarfire-soc-bsp`.

### Method A: Automated script (recommended)

Repository layout: this bundle lives under `PF_Linux` next to `yocto-dev/` (e.g. `~/PF_Linux/tmp_ClickBoard/polarfire-soc/THUMBSTICK_COM_09032`).

```bash
cd ~/PF_Linux/tmp_ClickBoard/polarfire-soc/THUMBSTICK_COM_09032
chmod +x install_and_build.sh
./install_and_build.sh
```

The script applies patches, ensures the FIT line includes fabric + thumbstick `dtbo`, copies **thumbstick** and **fabric gpio** `.dtso` files, sources the Yocto environment, cleans affected recipes, and builds **`mchp-base-image`**.

Optional: `SKIP_CLICK_BSP_RESET=1 ./install_and_build.sh` skips the pre-step that resets other Click bundles’ BSP changes.

### Method B: Manual integration

1. Copy **`mpfs_icicle_thumbstick.dtso`** and **`../FABRIC_GPIO_COMMON/overlay/mpfs_icicle_fabric_gpio.dtso`** to `BSP/recipes-bsp/dt-overlay-mchp/files/`.
2. Merge **`kernel/mcp320x.cfg`** into `BSP/recipes-kernel/linux/files/mpfs-icicle-kit-all/`.
3. Update **`dt-overlay-mchp_git.bbappend`**, **`linux-mchp_6.%.bbappend`**, and **`boot.cmd`** using the files under `snippets/`.

Then run **Building the Image** below.

### Method C: Patches only

From the **`PF_Linux` repository root** (where `yocto-dev/` exists):

```bash
patch -p1 < tmp_ClickBoard/polarfire-soc/THUMBSTICK_COM_09032/patches/0001-dt-overlay-mchp-add-thumbstick-dtso.patch
patch -p1 < tmp_ClickBoard/polarfire-soc/THUMBSTICK_COM_09032/patches/0002-add-kernel-fragment-mcp320x.cfg.patch
patch -p1 < tmp_ClickBoard/polarfire-soc/THUMBSTICK_COM_09032/patches/0003-linux-mchp-bbappend-add-mcp320x-cfg.patch
patch -p1 < tmp_ClickBoard/polarfire-soc/THUMBSTICK_COM_09032/patches/0004-mcp320x-cfg-enable-keyboard-gpio-polled.patch
patch -p1 < tmp_ClickBoard/polarfire-soc/THUMBSTICK_COM_09032/patches/0005-mcp320x-cfg-input-evdev-m.patch
```

Then copy both overlays:

```bash
cp tmp_ClickBoard/polarfire-soc/THUMBSTICK_COM_09032/overlay/mpfs_icicle_thumbstick.dtso \
   yocto-dev/meta-mchp/meta-mchp-polarfire-soc/meta-mchp-polarfire-soc-bsp/recipes-bsp/dt-overlay-mchp/files/
cp tmp_ClickBoard/polarfire-soc/FABRIC_GPIO_COMMON/overlay/mpfs_icicle_fabric_gpio.dtso \
   yocto-dev/meta-mchp/meta-mchp-polarfire-soc/meta-mchp-polarfire-soc-bsp/recipes-bsp/dt-overlay-mchp/files/
```

Ensure **`boot.cmd`** contains the fabric and thumbstick FIT configs (see `snippets/boot.cmd.bootm-line.txt`). Then **Building the Image**.

If a patch fails, use snippets and Method B for that step.

## Building the Image

Use after **Method B** or **C**. (**Method A** runs these.)

```bash
cd ~/PF_Linux/yocto-dev
source openembedded-core/oe-init-build-env build
bitbake dt-overlay-mchp -c cleansstate
bitbake linux-mchp -c cleansstate
bitbake u-boot-mchp -c cleansstate
bitbake mchp-base-image
```

## Verification

After booting the new image:

```bash
# ADC (IIO)
ls /sys/bus/iio/devices/
cat /sys/bus/iio/devices/iio:device0/name

# Pushbutton — load evdev module if built as module: modprobe evdev
ls -l /dev/input/event*
```

Use **`evtest`** (from the `evtest` package, if installed) on `/dev/input/event*`, or read events from your application.
