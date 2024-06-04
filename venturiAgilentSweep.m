% Program to collect spectra using Venturi 6600 swept laser and
% dual-channel power meters (81635) on Agilent 8164B slot 2
clear; delete(instrfindall);
ven = venturi_connect();
agi = start_laser(); % legacy function name, not using laser on Agilent
%% Setup sweep
startWavelength = 1520;
stopWavelength = 1620;
sweepRate = 10;
wavelengthStep = 0.005; 
laserPower = 9.9; % dBm, 0 to 9.9
powerMeterRange1 = -30; % dBm, multiples of 10 from -60 to 10
powerMeterRange2 = 10; % dBm, multiples of 10 from -60 to 10

venturi_set_power(ven, laserPower);
[actualRange, actualRate] = venturi_sweep_setup(ven, sweepRate, startWavelength, stopWavelength);
% compute parameters to give to Agilent power meter logging
% the points collected are not instantaneous - they average over the
% interval spacing (for now, unless we set up Stability power meter mode)
avgTime = wavelengthStep/actualRate;
% as such, the calc below is not a fencepost error - our measurements are
% the gaps, not the posts in the fence
numPts = actualRange/wavelengthStep;
% our array of wavelengths, then, is the CENTER of these gaps!
lambdaArray = startWavelength + wavelengthStep*(0.5 + 0:(numPts));
agilent_set_range(agi, powerMeterRange1, 1);
agilent_set_range(agi, powerMeterRange2, 2);
agilent_setup_logging(agi, numPts, avgTime);
%% run sweep

agilent_arm_logging(agi);
venturi_output(ven, true);
venturi_sweep_run(ven);
venturi_sweep_run(ven);
loggingSuccessful = agilent_wait_for_logging(agi);
if(loggingSuccessful)
    [channel1, channel2] = agilent_get_logging_result(agi);
    agilent_reset_triggers(agi);
else
    warning("Logging did not finish.");
end
%%
figure; hold on;
plot(lambdaArray, 10*log10(channel1) + 30);
plot(lambdaArray, 10*log10(channel2) + 30);
hold off;
xlabel("Wavelength");
ylabel("Power (dBm)");
%%
figure; hold on;
plot(lambdaArray, 10*log10(channel1./channel2));
hold off;
xlabel("Wavelength");
ylabel("Transmission (dB)");
% wait for Venturi to *think* its done before we can turn off laser
% fprintf("Waiting for Venturi...");
% while(~strcmp(venturi_extract_result(query(ven, ":STAT?"),6),'Complete'))
%     fprintf('.');
%     pause(1);
% end
% venturi_output(ven, false);

%%
[output_filename, output_path] = uiputfile('*', 'Select location to save data:');
if(output_filename)
    save(strcat(output_path,output_filename), 'actualRate', 'avgTime', 'laserPower', 'channel1', 'channel2', 'lambdaArray');
else
    disp("File save cancelled");
end

