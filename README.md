# Introduction #
HEY OH LET'S GO is a framework built around the LTE system toolbox available in Matlab.
It uses functions from the toolbox to perform complete DL processing of the main data channel.
It also simulates a multi-UE and multi-eNodeB scenario.
Very addictive stuff.

# Environment requirements #
Matlab (tested version is R2016B) and included LTE system toolbox.

WINNER II toolbox is required if `winner` is used as channel mode.

# Features

SONOHI is intended modular, however built around a main simulation loop which has a granularity of 2 LTE resource blocks, e.g. one scheduling round.

The loop is split into three major parts, a transmitter, a channel and a receiver. Requirements and features are listed below:

## Assumptions

* Full synchronization

## Initial Requirements

* Map layout with x,y,z coordinates given in meters.
* Number of `Users` and their positions (currently initialized as random)
* Number of `Stations` and their types.

## Transmitter

* (Initial) User association based on basic path loss
* CellID broadcast BCH
* PSS and SSS signals for synchronization.
* Realistic scheduling using non-full buffers
* Power tracking of eNBs
* OFDM modulation based on number of RBs

## Channel

Currently two modes:

`eHATA`

* For path loss: Extended Okumura Hata model [[1]](https://github.com/usnistgov/eHATA)
* For fading: MATLAB lteFading based on 3GPP fading requirements

`winner`

WINNER II is implemented as a toolbox in MATLAB [[2]](https://se.mathworks.com/matlabcentral/fileexchange/59690-winner-ii-channel-model-for-communications-system-toolbox) which enables highly customizable propagation scenarios.

Please note, no MIMO is supported yet.

## Receiver

* Channel estimation
* Channel equalization
* EVM computation
* CQI selection
