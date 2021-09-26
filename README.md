# UCSD_UNO_active_testing

Repository with ready-to-use MATLAB scripts to perform common active characterization experiments.

## Download & Use

To use this code, simply click the "Code" drop-down menu at the top-right of this page and select "Download ZIP". After extracting the archive, simply open the repository folder in MATLAB and ensure all subdirectories are added to MATLAB's path. You should then be able to run any of the ready-to-use experiment scripts in the main directory of the repository.

This code currently only supports tuning heaters with a Keithley 2400 and measuring optical behavior with the Agilent 8164B in the CSPTF.
In all code:

* the script can be run all the way through to setup equipment, set experiment parameters, perform the experiment, save the results (with save destination selected using GUI), and plot the results
* or, the script can be run in sections to do each of these tasks separately
* heater tuning can be done either with the Keithley as a voltage source, current source, or as a power source (voltage source with uniform steps in mW)
* the units in all user-facing scripts are:
  * V for voltage
  * mA for current
  * mW for electrical power
  * dBm for optical power
  

## Experiment scripts

* spectrumHeaterSweep.m

  * Acquires transmission spectra as a function of heater tuning.

* singleWavelengthHeaterSweep.m
  
  * Measures the transmission of a single wavelength as a function of heater tuning.
  
* wavelengthSweep.m
  * Take a single spectrum measurement.
  
## Notes
I have done a fair amount of testing to ensure this code won't blow up any chips (there are a lot of built-in safety features) but I have no guarantees. If you encounter any issues in this code, please let me know so I can fix them!

This is only the first version of this code and the future goal is for this repository to become a modular, easy-to-use library of MATLAB scripts for doing common experiments on any equipment in the UNO labs. More info can be found in FuturePlans.md.
