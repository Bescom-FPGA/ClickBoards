# PolarFire SoC — Click board bundles

This directory holds **MikroE Click board** integration bundles for **PolarFire SoC** evaluation kits (e.g. Icicle Kit) and similar boards that use the Microchip Yocto layer **`meta-mchp-polarfire-soc`**.

Each subfolder is one **bundle**: overlays, kernel fragments, patches, and optional `install_and_build.sh` scripts, with its own `README.md`.

## Bundles

| Bundle | Click board | Notes |
|--------|-------------|--------|
| [`proximity-3-vcnl4200/`](proximity-3-vcnl4200/) | MIKROE Proximity 3 (Vishay VCNL4200) | Icicle mikroBUS, I2C; see bundle `README.md` for machine and Libero assumptions. |

## Parent repository

See the [repository root `README.md`](../README.md) for overall layout and prerequisites.
