function key_set_I(key, current)
% Set output current of keithley in mA - if in V source mode, will do nothing
% Native Keithley unit is amps, but this function uses mA
    current_mA = current/1000;
    fwrite(key, ['sour:curr:level ' num2str(current_mA)]);
end
