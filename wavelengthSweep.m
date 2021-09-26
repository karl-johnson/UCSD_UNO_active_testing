%% Program to acquire single transmission spectrum from 8164B
%% Initialize Connection to Laser
delete (instrfindall); % Delete all existing instruments
laser = start_LMS(); % Initialize and connect laser
%% Acquisition Parameters
% Laser source settings (all in nm)
lambda_start = 1460; % nm, minimum 1460
lambda_end = 1600; % nm, maximum 1600
lambda_step = 0.01; % nm, minimum TODO
lambda_speed = 10; % sweep speed in nm/s, min TODO and max TODO
laser_power = 0;  %dbm, min TODO and max TODO (on output 2)

% Optical power meter settings
range = -10; % dB, will be rounded to nearest 10
%% Run Acquisition
N = LMS_set_param(laser,lambda_speed,lambda_step,laser_power,lambda_start,lambda_end,range);
[lambdaList,transmissionList] = laser_scan(laser,N);
%% Plot result
laser_power_mW = 10^(laser_power/10);
figure;
plot(lambdaList, 10*log10(transmissionList/laser_power_mW));
xlabel("Wavelength");
ylabel("Transmission (dB)");

%% %% Save Result %% %%
% Saves all variables into .mat file (locat. picked using GUI)
[output_filename, output_path] = uiputfile('*', 'Select location to save data:');
if(output_filename)
    save(strcat(output_path,output_filename));
else
    disp("File save cancelled");
end
