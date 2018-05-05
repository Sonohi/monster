Traffic
==============
MONSTeR currently supports 3 traffic models:

1. Video streaming
2. Web browsing
3. Full buffer

The first 2 models are generated from realistic traffic sources, while the full buffer model is primarily included for testing and benchmarking.
All the traces used in MONSTeR consist of timestamps in seconds and a corresponding packet size in bits.
The traces are generated for approximately 600 seconds. 
If the simulation is longer than that, then the **TrafficGenerator** will just restart at the beginning of the source.

Video streaming
^^^^^^^^^^^^^^^^^^^
The video streaming trace is based on the sampling of the popular *Big buck bunny* video*.
The version used is the MP4-encoded 1920x1080 availble `here <https://peach.blender.org/download/>`_ .
The sampling is done using `FFmpeg <https://ffmpeg.org/>`_ .

Web browsing
^^^^^^^^^^^^^
The web browsing model is based on a browsing session of `CNN <https://edition.cnn.com/>`_.
The trace has been captured with the following setup:

1. Date and time: 2018.05.02 at 09.30 CET 
2. Device: *Samsung SM-G950F*
3. Browser: *FireFox v.59.0.2* 
4. Monitoring app: *tPacketCapture 2.0.1, Taosoftware co.,LTD* 
5. Network: LTE-A

The trace has been generated for 102 seconds of browsing and then replicated 6 times.
During the 102 seconds the following actions were performed:

1.  At ``t = 0`` the website was intiially requested
2.  At ``t = 39 s`` the first `article <https://edition.cnn.com/2018/05/01/politics/trump-lawyers-showdown-special-counsel/index.html>`_ on the main page was requested.
3.  At ``t = 56 s`` the second `article <https://edition.cnn.com/2018/05/01/politics/harold-bornstein-trump-letter/index.html>`_ was requested.
4.  At ``t = 84 s`` the third `article <https://edition.cnn.com/2018/05/01/entertainment/kanye-west-slavery-choice-trnd/index.html>`_ was requested.
5.  At ``t = 102 s`` the capture ended with the third article fully rendered.

In all cases, the following step had not been taken until the page was fully rendered in the browser.

Full buffer
^^^^^^^^^^^^
The full buffer traffic model differs from the previous 2 ones as it is a non-realistic model.
This traffic model simply ensures constant 10000000 bits every traffic timeslot of 0.1 seconds.

.. automodule:: traffic
.. autoclass:: trafficGeneratorBulk



Traffic Generator
--------------------
.. autoclass:: TrafficGenerator
    :members: getStartingTime, updateTransmissionQueue