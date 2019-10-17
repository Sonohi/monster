## Unreleased
- Uplink PUSCH generation and nonstatic UL scheduler
- MIMO support 
- Logic graph plotting of network entities

## 1.0.2 - 2019-10-17

### Added
- Added SRS channel estimation
- Added backhaul functionalities for controlling the aggregation of traffic sources

### Changed
- Revised and improved user association structure between eNB and Users
- Revised the scheduler in DL. Now stored under the Mac property in the eNB
- Revised the Config to be read only and not changed during simulation
- Revised plotting during simulation

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
