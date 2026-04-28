# Click Boards for PolarFire SoC Icicle Kit

This repository contains integration bundles for **MikroE Click boards** used with the **PolarFire SoC Icicle Kit** (and related kits) via the mikroBUS header, under the Microchip **Yocto BSP** (`meta-mchp`).

Each bundle provides device tree overlays (`.dtso`), kernel configuration fragments (`.cfg`), integration patches, and optional scripts where documented.

## Repository layout (by platform)

Folders follow the same split as [linux4microchip/meta-mchp](https://github.com/linux4microchip/meta-mchp) (`meta-mchp-polarfire-soc`, `meta-mchp-pic64`, `meta-mchp-mpu`, etc.):

| Directory | Purpose |
|-----------|---------|
| [`polarfire-soc/`](polarfire-soc/) | PolarFire SoC evaluation kits (e.g. Icicle + mikroBUS). |
| [`pic64/`](pic64/) | PIC64 MPU family bundles (reserved for future use). |
| [`mpu/`](mpu/) | SAM and other MPU bundles (reserved for future use). |

## Supported bundles

### Click boards

| Click board | Sensor / IC | Interface | Bundle path |
|-------------|-------------|-----------|-------------|
| **MIKROE Proximity 3 Click** | Vishay VCNL4200 | I2C | [`polarfire-soc/proximity-3-vcnl4200/`](polarfire-soc/proximity-3-vcnl4200/) |
| **MikroE Thumbstick Click** (COM-09032 / MIKROE-1627) | MCP3204 ADC | SPI1 + Fabric GPIO (INT / button) | [`polarfire-soc/THUMBSTICK_COM_09032/`](polarfire-soc/THUMBSTICK_COM_09032/) |

### Shared FPGA / overlay (no Click SKU)

| Purpose | Contents | Bundle path |
|---------|----------|-------------|
| **Fabric CoreGPIO (`fabric_gpio`)** — used by Thumbstick (and OLED / similar overlays that reference `&fabric_gpio`) | DT overlay `mpfs_icicle_fabric_gpio.dtso`, optional Libero **`MPFS_ICICLE_KIT_BASE_DESIGN_THUMBSTICK_CLICK.job`** | [`polarfire-soc/FABRIC_GPIO_COMMON/`](polarfire-soc/FABRIC_GPIO_COMMON/) |

Thumbstick integration **chains** `mpfs_icicle_fabric_gpio.dtbo` **before** the board overlay in U-Boot FIT; copy **`FABRIC_GPIO_COMMON`** overlay sources when building Thumbstick (see that bundle’s `README.md`).

## How to use

Open the bundle directory and follow its `README.md`.

Examples:

```bash
cd polarfire-soc/proximity-3-vcnl4200
cat README.md
```

```bash
cd polarfire-soc/FABRIC_GPIO_COMMON
cat README.md
```

```bash
cd polarfire-soc/THUMBSTICK_COM_09032
cat README.md
```

## General prerequisites

- A Yocto build that includes **Microchip `meta-mchp`**.
- **`mpfs-icicle-kit-*`** machine and BSP paths given in each bundle’s `README.md`.
- **Hardware:** mikroBUS / SPI / I2C / GPIO routing must match the bundle (MSS vs Fabric CoreGPIO, Libero `.pdc`, optional FPGA programming job). See each bundle’s `README.md`.
