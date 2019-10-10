
# Introduction
This readMe file explains how to use the MONSTER simulation tool to examine throughput experience at end users. This provides an understanding of parameters affecting the throughput at the user side (DL only). 

# Requirements
To use the MONSTER simulation tool the following requirements must be met:

* Matlab version 2018a or newer installed and running - including the [LTE system toolbox](https://se.mathworks.com/products/lte-system.html) and dependencies.
* A clone of the toolbox from [Github](https://github.com/Sonohi/monster)

# Getting started
Once the clone is copied to your local machine open Matlab and follow these steps:
* Navigate to the root of the toolbox (called "monster"). 
* Run the `install.m` script, either from the editor or by calling it in the command window of Matlab. This adds all the folders and subfolders to the Matlab path. 
* You are now ready to use the tool.

# Run script
To easily get started a series of simulation examples have been prepared. To acces these directly go to the next section on how to process the results. 

The prepared script `ueThroughputExample.m` starts a series of simulations. These can be run in parallel with Matlab, but beware that this is not supported by all computers. In the `ueThroughputExample.m` script line 16 one can change the `parfor` to `for` running the simulations sequencial instead of in parallel. Most computers should be able to run in parallel and for computers with older hardware, one can configure the parallel computations to fit the limits of the computer - see this [guide](https://se.mathworks.com/help/parallel-computing/parallel-preferences.html).

Running the sricpt may take several minutes, depending on the hardware.

## What does the script do?
The `ueThroughputExample.m` script starts a series of simulations, each with a seperate scenario. The 5 predfined scenarios are all run for 100ms:
* **Baseline:** A baseline scenario with 1 macro site with 3 cells, each with 10MHz bandwith (same frequency). There is 25 users in the area and the backhaul capacity is capped at a total of 1Gbps.
* **Bandwidth:** Same as the baseline scenario, except another 10MHz of bandwidth is added.
* **With Micro:** Same as the baseline scenario, except 1 microcell is added pr. macrocell
* **Without Backhaul** Same as the baseline scenario, except with all delay and limitations in backhaul removed.
* **With Backhaul** Same as the baseline scenario, except for the backhaul, which now is limited to 10Mbps.

After running all these scenarios a `.mat` file for each scenario is available in the corresponsing folder. The `.mat` files contain the traffic description and the recorded metrics. The files are saved in a seperate folder for each day. The folders can be seperated by the names as they contain the date (in the format "yyyy.mm.dd").

# Process results
A script to plot the results of the example is available. The `processUeResults.m` will load the `.mat` files in each folder. The folders chosen depends on the chosen date. To choose a specific date change the string in line 8 in the `processUeResults.m` to the date chosen. If no date is chosen today is chosen. 

If the `ueThroughputExample.m` script has not been run, change the date in line 8 of the `processUeResults.m` script to match a date found in the results folder under the "ueThroughput" folder, to view sample data.

After running the `processUeResults.m` script 4 figures should appear and can be examined. Figure 1-3 compares the traffic arrived from the source to the throughput the users experience. Note that figure 1 compares for 3 scenarios as these have the same throughput from the backhaul.

Figure 4 is a comparison of the CDF functions for the throughput of the 5 different scenarios.

# Interpretation


The scenarios all differ, and thus is each [CDF](https://en.wikipedia.org/wiki/Cumulative_distribution_function) different from the others. Some differ more than others.

You should see that the two most alike is the **Without Backhaul** and **Baseline** scenarios. Since the backhaul for the baseline scenario is not the bottleneck, the air interface is, thus removing the backhaul only gives a slight shift to the right. By adding a limiting bottleneck in the backhaul the CDF shift to left as one can see for the **With Backhaul** scenario. 

For more throughput on the air interface adding more bandwidth or eNodeBs will do. From the **Bandwidth** scenario the CDF shifts right as more bandwidth are assigned, thus providing more capacity. The same is the case for the **With Micro** scenario, where the addition of the 3 microsites increases the capacity, enabling higher throughput. 


