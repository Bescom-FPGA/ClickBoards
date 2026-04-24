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

## Supported Click boards

| Click board | Sensor / IC | Interface | Bundle path |
|-------------|-------------|-----------|-------------|
| **MIKROE Proximity 3 Click** | Vishay VCNL4200 | I2C | [`polarfire-soc/proximity-3-vcnl4200/`](polarfire-soc/proximity-3-vcnl4200/) |

## How to use

Open the bundle directory and follow its `README.md`.

Example (Proximity 3 on Icicle):

```bash
cd polarfire-soc/proximity-3-vcnl4200
cat README.md
```

## General prerequisites

- A Yocto build that includes **Microchip `meta-mchp`**.
- For the Proximity 3 bundle: **`mpfs-icicle-kit-*`** machine and the paths described in that bundle’s `README.md`.
- **Hardware:** mikroBUS wired as assumed in the bundle (I2C bus, address, Libero / MSS vs fabric). See each bundle’s `README.md`.
