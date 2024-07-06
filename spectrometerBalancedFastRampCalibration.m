% spectrometer sweep where we quickly ramp two heaters at the same time 
% using channels 1 and 2 on keithley
clear;
delete (instrfindall); % Delete all existing instruments
agi = start_laser(); % Initialize and connect Agilent power meter
ven = venturi_connect(); % Connect to Venturi laser
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
%lambda_array_nm = [1520 1540 1560 1580 1600 1620];
lambda_array_nm = [1620:-20:1520];
detector_range = -50; % power meter range, dBm
sampling_interval = 5e-4; % how often to sample optically, seconds.
start_warmup_time = 5;
% electrical settings
compliance_current = 70e-3; % A
compliance_voltage = 70; % V
heater_R = 928.6;
P_range = 4000e-3; % W
P_tot = P_range; % only change this if we want to try narrower sweeps at elevated temp
start_time = 0.5; % seconds
ramp_time = 1; % seconds
end_time = 0.5;
P_num = 2001; % # of pts to split ramp into
supply_interval = ramp_time/(P_num-1); % how often power supply is updated, min 10 us
start_num = start_time/supply_interval;
end_num = end_time/supply_interval;

[I_inc, I_dec] = genBalancedPowCurrentLists(heater_R, P_tot, P_range, ...
    start_num, P_num, end_num);
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
total_time = start_time + ramp_time + end_time;
time_array = 0:sampling_interval:total_time;
power_time_array = 0:supply_interval:total_time;
% hacky fix of off-by-one
time_array = time_array(1:end-1);
sampling_num = length(time_array);
agilent_setup_logging(agi, sampling_num, sampling_interval);
power_per_optical_sample = P_range/ramp_time * sampling_interval;
figure; hold on;
plot(power_time_array, I_inc);
plot(power_time_array, I_dec);
hold off; xlabel("Time (s)"); ylabel("Current (A");
fprintf("Sweep time %1.1f s, %d optical samples at %.3e mW per optical sample\n", ...
    total_time, sampling_num, 1e3*power_per_optical_sample);

%% Run Calibration
% Set Save directory and prefix
[file_prefix, save_dir] = uiputfile('*', 'Select location and prefix where data will be saved:');
if(~file_prefix)
    error("You must select a save location");
end
num_lambda = length(lambda_array_nm);
lambda_array_m = lambda_array_nm*1e-9;
% turn up sweep rate on venturi so it doesn't take forever to move to the
% desired wavelength (not sure if this works??)
venturi_sweep_rate(ven, 100);
% Change timeouts
max_wait_time = total_time + 5; % time to wait for agilent before timing out
laser.Timeout = max_wait_time; % increase VISA timeout 
% Warm-up time at start
kes_output(kes, true);
fprintf("Pausing for %d seconds to warm-up...", start_warmup_time);
pause(start_warmup_time);
for lambda_index = 1:num_lambda
    kes_output(kes, true);
    clear channel1 lambda
    this_lambda_nm = lambda_array_nm(lambda_index);
    venturi_set_wavelength(ven, this_lambda_nm);
    lambda = 1e-9*this_lambda_nm;
    fprintf("Running sweep for %1.0f nm...", this_lambda_nm);
    agilent_arm_logging(agi, detector_range);
    fprintf("Agilent armed...");
    kes_trig_sweep(kes);
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
    this_filename = sprintf('%s_%d.mat', file_prefix, this_lambda_nm);
    save(fullfile(save_dir, this_filename), ...
        'time_array', 'channel1', 'channel2', 'heater_R', ...
        'P_range', 'P_tot', 'P_num', 'supply_interval', 'lambda');
    %close(f);
    pause(5);
end
kes_output(kes, false);
%% Plot result
figure; hold on;
plot(time_array, 10*log10(abs(channel1)) + 30, 'r-');
%plot(time_array, 10*log10(abs(channel2)) + 30), 'b-';
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