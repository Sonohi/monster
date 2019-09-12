## Unreleased
- Simple backhaul network.
- Uplink PUSCH generation and channel estimation from SRS

## 1.0.1 - 2019-09-12

### Added
- Added method for calculating the interference from cells in the same tier based on frequency subcarriers.
- Added method for calculating and recording SINR and CQI both at wide-band and at sub-band level.

### Changed
- Revised `Channel.interferenceType` attribute in `MonsterConfig` to allow for additional frequency-based interference calculation.
- Revised CQI and SINRdB properties in `ueReceiverModule` to account for wide-band and sub-band measurements.
- Revised metric recordings and tests variable names to reflect wide-band and sub-band measurements.

## 1.0.0 - 2019-08-29

### Added
- Started CHANGELOG file to highlight relevant updates across versions.
- Added `Site` class to represent base station sites with multiple cells.
- Added generation of `Sites` and their positioning to follow the heterogeneous pattern in ITU-R M.2412-0 (8.3.2).
- Added test for `MetricRecorder`.
- Added scenario-based test for `basicScenario`.
- Added test for main simulation loop.

### Changed
- Renamed all references to `Stations` to use `Cells` instead for more consistent naming.
- Changed generation of Manhattan grid to allow custom values for area, road width and building width.

### Removed 
- Removed HPC scripts for batch simulations.
- Removed pico cell tier.
- Removed static buildings file with coordinates.
