![MONSTeR](https://raw.githubusercontent.com/Sonohi/monster/master/docs/resources/graphics/monster.png)

# Introduction
MONSTeR (MObile Networks SimulaToR) is a framework built around the LTE system toolbox available in MATLAB.
It uses functions from the toolbox to perform complete DL and UL processing of the main data channel.
It also simulates a multi-UE and multi-eNodeB scenario.
The entire framework has just been largely re-factored to adopt a class-based structure that provides better scalability and flexibility.
It should be considered in **alpha** stage and updated frequently.
If you encounter bugs or some unexpected behaviour, please open an issue.
Contributors are welcome and encouraged! 
We have an always-growing number of feature requests, so feel free to pick or just go ahead with your own, following the style and phylosophy of the existing modules.

# Environment requirements
MATLAB and included [LTE system toolbox](https://se.mathworks.com/products/lte-system.html).
Tested versions of MATLAB are:
	
* 2017b
* 2018a 
* 2019a

# Getting started
When starting off with the project, it's important to navigate to the correct project folder in MATLAB and add the project folder and its subfolders to the path. 
This can also be achieved by running the `install.m` script at the root of the project.

# Overall logic and organisation
MONSTeR relies heavily on the usage of classes in MATLAB. 
These are fairly similar to those one would typically find in other object-oriented frameworks in other languages.

The project `main.m` file is the one that starts off a simulation process.
It creates an instance of the overall system configuration from the class `MonsterConfig` and a simulation logger from the `Logger` class.
Such objects can then be passed as parameters to the constructor of the main simulation object, that is an instance of the class `Monster`.
The instance of the `Monster` class created is used in the main simulation loop, which has a granularity of 2 LTE resource blocks, e.g. one scheduling round.

For each round of the simulation, 4 top methods are called to execute a simulation step. 
These are:

1. `setupRound` sets values for the current simulation round, such as scheduling round, time elapsed, etc.
2. `run` executes the core of the simulation round, calling the private methods of the class to perform the following:
	* `moveUsers` updates the position of the UEs in the scenario, based on the mobility pattern assigned (from the `Mobility` class).
	* `associateUsers` evaluates periodically the UE-eNodeB associations to potentially performs re-attachments or initiate handovers.
	* `updateUsersQueues` based on the traffic generation selected in the class `TrafficGenerator`, it updates the transmission queues for the UEs.
	* `schedule` performs the (multi) user scheduling for the downlink. Various scheduling policies/algorithms can be supported, provided the interfaces are respected. 
	The current implementation supports a _weighted round robin_.
	* `setupEnbTransmitters` takes the scheduling decisions performed at the eNodeB to run the relevant processing for Transport Blocks, Codewords and waveforms for the downlink in the class `enbTransmitterModule`.
	* `downlinkTraverse` performs the downlink traversal with the waveforms generated through an instance of the `MonsterChannel` class.
	* `downlinkUeReception` handles the reception of the waveforms at the UE side and processes results for lower-layer performance metrics, in case the demodulation of the received waveform is successful. This is handled by the `ueReceiverModule`.
	* `downlinkUeDataDecoding` uses the processing of the previous step to attempt the decoding of the codeword received. In case enabled, this is also the point where retransmission conditions are evaluated from the classes `HarqRx` and `ArqRx`.
	* `setupUeTransmitters` based on the feedback the UE needs to send in the UL, the UE transmitters (from the class `ueTransmitterModule`) are setup to construct the relevant waveform that can contain CQI and/or retransmission feedback values.
	* `uplinkTraverse` performs the traversal in uplink of the `MonsterChannel` instance for the UE-generated waveforms.
	* `uplinkEnbReception` performs similarly to its downlink counterpart in demodulating and decoding the received waveforms at the eNodeb. If retransmissions are enabled, the content is also used to process relevant steps for the `HarqTx` and `ArqTx` instances at the eNodeB.
3. `collectResults` processes and records all the results for the simulation round using an instance of the `MetricRecorder` class.
4. `clean` performs the relevant resets and cleanup of the variables used in the round and prepares the various object instances for the next round. Relevant variable values that should be used for a time evolution of the simulation nodes are not reset at this stage.

The simulation is then completed for the number of rounds configured and the results are made available as part of the `Monster` object created in the attribute `Results`.

# Performance metrics
The framework uses a class for taking care of recording performance metrics from the simulations.
The details of this class can be found in `/results/MetricRecorder.m`.
The key concepts are that one defines a class property for each of the metrics that are deemed interesting to record throughout the simulations (e.g. *powerConsumed* for the power consumed by an eNodeB).
In additions to this, one has also to define a method with which such metric is recorded.
See for example the method *recordPower* that takes care of recording the power consumed by the eNodeB.
Finally, a metric is typically a UE-side metric or an eNodeB-side metric. 
To ease the code and make it more scalable, there are 2 wrapper methods that are the only ones called from the main simulation loop. 
These are `recordEnbMetrics` and `recordUeMetrics`. When a new metric is added, the metric-recording method should be called from inside one of these 2 directly.
As regards the structure of the data produced, they are normally recorded once per scheduling round, thus rows represent the time evolution of the metric in the simulation. Columns on the other hand. represent either the number of UEs, or those of the eNodeBs, depending on the metric.

# Scenarios
The number of parameters available in an instance of `MonsterConfig` is large. 
For most users, only a fraction of these parameters will ever be relevant, while some others will become more interesting to modify while developing.
The recommended approach is to create a new subfolder in `scenarios/`, where the relevant setup of the scenario configuration can be carried out by changing only the relevant parameters.
For example in `scenarios/maritime/` an example is provided in `maritimeSweep.m` that substitutes the `main.m` script of the default simulation.
In it, it's possible to notice that, once an instance of `MonsterConfig` is initialised, some of its relevant attributes are modified from the default to match the desired scenario.

## Parallel simulation batches
MATLAB supports the possibility of running parallel batches of simulations. This is achieved as part of the scenarios by constructing a _wrapper script_ for the `main.m` of that particular scenario that administers the parallel execution. 
Still in the case of the `scenarios/maritime/` used above, the _wrapper script_ is called `batchMaritime.m` and it is used to invoke the `batchSimulation.m` script that plays the role of the `main.m` script, but takes a number of relevant parameters when invoked that launches a simulation with different scripted parameters.
It is typically beneficial to redirect logs to file in this case and save simulation results to files.


# Charting utility

The charting utility included in the project at `/charts/` is fully optional and provided as a possible tool among the many available.
It is based on [pyecharts](https://pyecharts.org/#/) a Python port of the Echarts library from Baidu.
It is suggested to create subfolders based on the project started, e.g. `/charts/maritime`;

## Installation
One option to install the library and get going is to use [Anaconda](https://anaconda.com), but feel free to use other alternatives based on your environment/python preferences.
The following instructions are provided for Ubuntu 18.04, for other OS, please refer to the official [Anaconda installation docs](https://docs.anaconda.com/anaconda/).

### Download
Download the installer on [Anaconda's website](https://www.anaconda.com/distribution/).

### Ubuntu 18.04 Python 3.6 installation 
Assuming the installer has been downloaded in `~/Downloads/`, then follow the instructions for Anaconda in the [docs](https://docs.anaconda.com/anaconda/install/linux/).
Once the installation is finished, check also [the following link for Python 3.6](https://docs.anaconda.com/anaconda/user-guide/faq/#anaconda-faq-35).

### Pyecharts installation
Once the installation is completed and you are in a virtual environment as per documentation notes above, simply issue `pip install pyecharts` to add it.

## Usage 
Usage of _pyecharts_ can be done in several ways. One option is to rely on [Jupyter notebook](https://jupyter.org/) that is already included in the Anaconda distribution and an integration is also provided when installing _pyecharts_.

# Docs
Detailed documentation for the project, the various classes mentioned above and more is generated from in-code comments and available [here](https://sonohi.github.io/monster/). 

As of June 2019 the docs are being largely revised due to the major changes applied to the project to the more scalable class-based structure.

# Licence
**MONSTer** is release under **MIT** licence available in copy at the root of the repository.

