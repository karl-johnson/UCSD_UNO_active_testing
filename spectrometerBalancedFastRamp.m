% spectrometer sweep where we quickly ramp two heaters at the same time 
% using channels 1 and 2 on keithley
clear;
delete (instrfindall); % Delete all existing instruments
agi = start_laser(); % Initialize and connect Agilent power meter
% ven = venturi_connect(); % Connect to Venturi laser
kes = kes_start(); % Connect to keysight
%% Heater contact test
test_V_compliance = 10; % volts
test_I = 1e-3; % current, amps
kes_config_I_source(kes, test_V_compliance, 1);
kes_set_I(kes, test_I, 1, false);
R1_meas = kes_measure_resistance(kes, 1);
kes_config_I_source(kes, test_V_compliance, 2);
kes_set_I(kes, test_I, 2, false);
R2_meas = kes_measure_resistance(kes, 2);
fprintf("Channel 1 R = %1.1f ohms, Channel 2 R = %1.1f ohms \r\n", R1_meas, R2_meas);
%% Choose sweep params and send to equipment
% optical settings
detector_range = -50; % power meter range, dBm
sampling_interval = 5e-3; % how often to sample optically, seconds.
% electrical settings
heater_R = 928.6;
P_range = 1000e-3;
P_tot = P_range; % only change this if we want to try narrower sweeps at elevated temp
P_num = 2001;
supply_interval = 5e-3; % how often power supply is updated, min 10 us
compliance_current = 40e-3; % 1 mA
compliance_voltage = 40; % 1
[I_inc, I_dec] = genBalancedPowCurrentLists(heater_R, P_tot, P_range, P_num);
fprintf("---\n");
if(any(I_inc > compliance_current) || any(I_dec > compliance_current))
    error("Power/resistance settings will exceed compliance current! (I_max = %f and %f)", max(I_inc), max(I_dec));
else
    fprintf("I_max = %f and %f\n", max(I_inc), max(I_dec));
end
if(any(heater_R*I_inc > compliance_voltage) || any(heater_R*I_dec > compliance_voltage))
    error("Power/resistance settings will exceed compliance voltage! (R*I_max = %f and %f)", ...
        heater_R*max(I_inc), heater_R*max(I_dec));
else
    fprintf("R*I_max = %f and %f\n", heater_R*max(I_inc), heater_R*max(I_dec));
end


% "background" currents - what is on when the ramp isn't running?
background_index = 1;
background_current_1 = I_inc(background_index);
background_current_2 = I_dec(background_index);
% setup channel 1 as increasing
kes_setup_user_sequence(kes, 1, 'current', ... 
            I_inc, supply_interval, compliance_voltage);
% last argument here 'false' is a flag to use amps instead of mA - be
% careful!
kes_set_I(kes, background_current_1, 1, false);
% setup channel 2 as decreasing
kes_setup_user_sequence(kes, 2, 'current', ... 
            I_dec, supply_interval, compliance_voltage);
kes_set_I(kes, background_current_2, 2, false);

% use agilent "logging" mode which maximizes integration time for given
% sampling period
total_time = P_num * supply_interval;
time_array = 0:sampling_interval:total_time;
% hacky fix of off-by-one
time_array = time_array(1:end-1);
sampling_num = length(time_array);
agilent_setup_logging(agi, sampling_num, sampling_interval);
power_per_optical_sample = P_range/total_time * sampling_interval;
fprintf("Sweep time %1.1f s, %d optical samples at %.3e mW per optical sample\n", ...
    total_time, sampling_num, 1e3*power_per_optical_sample);
%% Run sweep
agilent_arm_logging(agi, detector_range);
kes_trig_sweep(kes);
% usually we would have hardware trigger but for now software trigger
% agilent
fwrite(agi, "trig 1");
max_wait_time = total_time + 5; % time to wait for agilent before timing out
laser.Timeout = max_wait_time; % increase VISA timeout 
loggingSuccessful = agilent_wait_for_logging(agi, max_wait_time);
% turn off outputs
kes_output(kes, false);
% get result
if(loggingSuccessful)
    [channel1, channel2] = agilent_get_logging_result(agi);
    agilent_reset_triggers(agi);
else
    warning("Logging did not finish in alloted time.");
end
%% Plot result
figure; hold on;
plot(time_array, 10*log10(abs(channel1)) + 30, 'r-');
plot(time_array, 10*log10(abs(channel2)) + 30), 'b-';
hold off;
xlabel("Time (s)");
ylabel("Power (dBm)");
%% Plot FFT

fft1 = abs(fft(channel1));
fft2 = abs(fft(channel2));
N = length(fft1);
fs = 1/sampling_interval;
freq_array = fs*(0:N-1)/N;
plot_idx = 1:round(N/2);
figure; 
loglog(freq_array(plot_idx), fft1(plot_idx), 'r-'); hold on;
plot(freq_array(plot_idx), fft2(plot_idx), 'b-');
hold off;
xlabel("Frequency (Hz)");
ylabel("FFT");
%% Save result
[output_filename, output_path] = uiputfile('*', 'Select location to save data:');
if(output_filename)
    save(strcat(output_path,output_filename), ...
        'time_array', 'channel1', 'channel2', 'heater_R', ...
        'P_range', 'P_tot', 'P_num', 'supply_interval');
else
    disp("File save cancelled");
end