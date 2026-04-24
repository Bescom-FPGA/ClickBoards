# MikroE Click Boards for PolarFire SoC Icicle Kit

This directory contains integration bundles for various **MikroE Click Boards** to be used with the **PolarFire SoC Icicle Kit** via its mikroBUS header.

Each bundle provides the necessary device tree overlays (`.dtso`), kernel configuration fragments (`.cfg`), and integration patches for the Microchip Yocto BSP (`meta-mchp`).

## Supported Click Boards

| Click Board | Sensor / IC | Interface | Directory |
|-------------|-------------|-----------|-----------|
| **Proximity 3 Click** | Vishay VCNL4200 | I2C | [`proximity-3-vcnl4200/`](proximity-3-vcnl4200/) |

## How to Use

Navigate to the specific directory for the Click Board you want to integrate. Each directory contains its own `README.md` with detailed instructions on how to apply the patches, copy the overlays, and rebuild your Yocto image.

For example, to integrate the Proximity 3 Click:

```bash
cd proximity-3-vcnl4200
cat README.md
```

## General Prerequisites

- A Yocto build environment set up with the **Microchip `meta-mchp`** layer.
- The `mpfs-icicle-kit-*` machine configuration.
- Your Libero FPGA design must have the mikroBUS pins routed to the appropriate MSS or Fabric controllers (e.g., MSS I2C0, Fabric CoreI2C, etc.). Check the specific board's `README.md` for hardware assumptions.
