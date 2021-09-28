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

## Known issues

When performing uniform-power-step sweeps, the voltage points are generated by first measuring the load resistance using the Keithley 2400's Auto-ohm function, which generally uses as low of a supply current as possible. Since the resistance can change at higher currents (due to non-ideal behavior in the probes/pads), the actual power values/increments applied in the sweep can vary quite a bit from the sweep parameters (P_start, P_end, P_step) selected before running the experiment. For this reason, you should always use the measured_V, measured_I, and measured_P variables saved after the experiment to know how much power was *actually* put through the device at each sample point.

When doing any wavelength sweep using the Agilent 8164B, sweeps that take longer than 10 seconds result in an error. This should be fixed soon.