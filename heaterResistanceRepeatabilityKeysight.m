clear;
delete (instrfindall); % Delete all existing instruments
kes = kes_start(); % Initialize and connect keithley
%%
kes_config_I_source(kes, 0.1)
kes_set_I(kes, 0.1);
[twoWire, fourWire] = kes_contact_resistance(kes);
contact = twoWire - fourWire;
fprintf("2-wire = %f, 4-wire = %f, diference = %f \n", twoWire, fourWire, contact);
%% Current sweep, with repeats.
numRepeats = 10;
i_min = 0;
i_max = 100;
i_step = 5;
i_list = i_min:i_step:i_max;
i_num = length(i_list);
v_comp = 100;
i_comp = i_max;
settle_time = 0;
time_between_repeats = 10;
function_handle = @doNothing;
kes_set_4wire(kes, true);
saveArray = zeros(i_num, 2, numRepeats);
for repeatIdx = 1:numRepeats
    thisList = i_list;
%     if(mod(repeatIdx,2))
%         thisList = i_list;
%     else
%         thisList = flip(i_list);
%     end
    [measured_V, measured_I, ~] = kes_do_I_list(...
        kes, thisList, v_comp, i_comp, settle_time, function_handle);
    saveArray(:, :, repeatIdx) = [measured_V,measured_I];
    pause(time_between_repeats);
end

%% Plot repeats overlaid
figure; hold on;
colors = cool(numRepeats);
for repeatIdx = 1:numRepeats
    plot(saveArray(2:end,1,repeatIdx)./saveArray(2:end,2,repeatIdx), "Color", colors(repeatIdx, :));
end
%% Random list
numIndividPts = 500;
i_list = i_max * rand(numIndividPts);
[measured_V, measured_I, ~] = kes_do_I_list(...
        kes, i_list, v_comp, i_comp, settle_time, function_handle);
%%
%plot(measured_I, measured_V, '.');
plot(measured_I, measured_V./measured_I, '.');
%% save result
[output_filename, output_path] = uiputfile('*', 'Select location to save data:');
if(output_filename)
    save(strcat(output_path,output_filename), 'saveArray', 'settle_time');
else
    disp("File save cancelled");
end
%% save random result
[output_filename, output_path] = uiputfile('*', 'Select location to save data:');
if(output_filename)
    save(strcat(output_path,output_filename), 'measured_I', 'measured_V');
else
    disp("File save cancelled");
end

function doNothing()

end