# Introduction #
MONSTeR (MObile Networks SimulaToR) is a framework built around the LTE system toolbox available in Matlab.
It uses functions from the toolbox to perform complete DL and UL processing of the main data channel.
It also simulates a multi-UE and multi-eNodeB scenario.
The entire framework is in **alpha** and updated frequently. 
If you encounter bugs or some unexpected behaviour, please open an issue.
Contributors are welcome and encouraged! We have an always-growing number of feature requests, so feel free to pick or just go ahead with your own.

# Environment requirements #
Matlab (tested version is R2017B) and included [LTE system toolbox](https://se.mathworks.com/products/lte-system.html).

# Features 
MONSTeR is intended modular, however built around a main simulation loop which has a granularity of 2 LTE resource blocks, e.g. one scheduling round.

The loop is split into three major parts, a transmitter, a channel and a receiver. Major features are listed below:

* Different traffic models (e.g. full buffer and video streaming)
* Multiple mobility patterns (pedestrian, vehicular)
* Customizable network layout and scenarios (number of sites, users, tiers of base stations and presence of buildings)
* Automatic Repeat reQuest (ARQ) and Hybrid Automatic Repeat reQuest (HARQ) for fast retransmissions
* Packets re-ordering at receiver using SeQuence Numbers (SQNs)
* Multi-user scheduling with customizable algorithms (e.g. greedy round robin)
* Complete Down Link Shared CHannel (DL-SCH) and Physical Downlink Shared CHannel (PDSCH) processing chain
* Generation of LTE-compliant Downlink and Uplink resource grid
* Complete Uplink Shared CHannel (UL-SCH) and Physical Uplink Shared CHannel (PUSCH) processing chain
* Different channel models and independent ones for UL and DL
* eNodeB power consumption tracking and load-based autonomous sleeping mode for energy saving

# Getting started

See `initParam.m` for configuration details. 
This is used by the main file for configuring the simulation. 
The structure of the framework is roughly is follows:

* Set configurations in `initParam.m`
* Run simulation by running `main.m`
* This executes the simulation script which contains the main loop.
* After the simulation is done, results are saved in the results folder
* Simulations can be replayed by running  `utils/replaySimulation/replaySimulation.m`

Alternatively, a Matlab app is provided where the majority of the parameters in the `initParam` file are available.
The file is called **monster.mlapp** at the root of the repo and runs the default folder loading at startup.

## Assumptions
As of 02.2018 the follwing assumptions are made for ease of implementation:

* Full synchronization
* Perfect backhaul (not for long :) )

## Initial Requirements

* Map layout with x,y,z coordinates given in meters.
* Number of `Users` and their positions (currently initialized as random)
* Number of `Stations` and their types.

### Downlink

See `enbTransmitterModule.m` and `ueReceiverModule.m`

#### Transmitter

* (Initial) User association based on basic path loss
* CellID broadcast BCH
* PSS and SSS signals for synchronization.
* Realistic scheduling using non-full buffers
* Power tracking of eNBs
* OFDM modulation based on number of RBs

#### Channel

Currently two modes:

`eHATA`

* For path loss: Extended Okumura Hata model [[1]](https://github.com/usnistgov/eHATA)
* For fading: MATLAB lteFading based on 3GPP fading requirements

`winner`

WINNER II is implemented as a toolbox in MATLAB [[2]](https://se.mathworks.com/matlabcentral/fileexchange/59690-winner-ii-channel-model-for-communications-system-toolbox) which enables highly customizable propagation scenarios.

Please note, no MIMO is supported yet.

#### Receiver

* Channel estimation
* Channel equalization
* EVM computation
* CQI selection


## Uplink

TODO

# Licence
**MONSTer** is release under **MIT** licence available in copy at the root of the repo.

