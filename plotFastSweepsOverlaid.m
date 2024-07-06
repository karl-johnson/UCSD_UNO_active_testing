[file, location] = uigetfile('.mat', 'Select One or More Files', 'MultiSelect', 'on');
if(iscell(file))
    numFiles = length(file);
else
    numFiles = 1;
    file = {file};
end
%%
cropIdxs = [1000:3000];
figure;
for i = 1:numFiles
    load(fullfile(location, file{i}), ...
        'time_array', 'channel1', 'channel2');
    thisDetrended = channel1./movmean(channel1,50) - 1;
    %thisDetrended = channel1 - movmean(channel1,100);
    %plot(time_array(cropIdxs), thisDetrended(cropIdxs), 'DisplayName', file{i});
    plot(time_array, channel1, 'DisplayName', file{i});
    
    if(i == 1)
        hold on;
    end
end
hold off; legend();
xlabel("Time (s)"); ylabel("Optical pwoer (mW)");
%% FFTs
figure; 
for i = 1:numFiles
   load(fullfile(location, file{i}), ...
        'time_array', 'channel1', 'channel2');
    thisDetrended = channel1./movmean(channel1,75) - 1;
    %thisDetrended = channel1 - movmean(channel1,100);
    thisFFT = abs(fft(thisDetrended(cropIdxs)-1)).^2;
    thisIdx = 1:round(length(thisFFT)/2);
    semilogy(thisFFT(thisIdx)./thisFFT(278)); %, 'DisplayName', sprintf("%1.0fnm", 1e9*lambda));
    if(i == 1)
        hold on;
    end
end
hold off; legend();
xlabel("Arb. FFT x axis units that I don't feel like scaling"); ylabel("Power spectral density");
%% Sweep durations

sweepTimes = []; sweepLambdas = []; sweepTimeSteps = [];
for i = 1:numFiles
    load(fullfile(location, file{i}), 'measurement_times', 'lambda');
    sweepTimes = [sweepTimes measurement_times(end)-measurement_times(1)];
    sweepLambdas = [sweepLambdas lambda];
    sweepTimeSteps = [sweepTimeSteps, seconds(diff(measurement_times))];
end
%plot(sweepLambdas, sweepTimes);
figure; plot(sweepTimeSteps);