## Unreleased
- Subcarrier-based interference calculation.

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
