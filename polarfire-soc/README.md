# PolarFire SoC — Click board bundles

This directory holds **MikroE Click board** integration bundles for **PolarFire SoC** evaluation kits (e.g. Icicle Kit) and similar boards that use the Microchip Yocto layer **`meta-mchp-polarfire-soc`**.

Each subfolder is one **bundle**: overlays, kernel fragments, patches, and optional `install_and_build.sh` scripts, with its own `README.md`.

## Bundles

### Shared overlay / FPGA artifact

| Bundle | Role |
|--------|------|
| [`FABRIC_GPIO_COMMON/`](FABRIC_GPIO_COMMON/) | Adds **`fabric_gpio`** (`microchip,coregpio-rtl-v3`) for mikroBUS lines tied to Fabric CoreGPIO. Includes optional **`MPFS_ICICLE_KIT_BASE_DESIGN_THUMBSTICK_CLICK.job`** (Libero FlashPro job: **mBUS_PWM**, **mBUS_INT** routed into that CoreGPIO, aligned with `mpfs_icicle_fabric_gpio.dtso`). Load this FIT overlay **before** board-specific `dtbo` where documented. |

### Click boards

| Bundle | Click board | Notes |
|--------|-------------|--------|
| [`proximity-3-vcnl4200/`](proximity-3-vcnl4200/) | MIKROE Proximity 3 (Vishay VCNL4200) | Icicle mikroBUS, I2C; see bundle `README.md`. |
| [`THUMBSTICK_COM_09032/`](THUMBSTICK_COM_09032/) | MikroE Thumbstick (COM-09032 / MCP3204) | SPI1 + **`&fabric_gpio`** for pushbutton; expects **`FABRIC_GPIO_COMMON`** overlay copied into the same Yocto build; see bundle `README.md`. |

## Parent repository

See the [repository root `README.md`](../README.md) for overall layout and prerequisites.
