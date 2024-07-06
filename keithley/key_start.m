function key = key_start()
% KEY_START Connect to Keithley 2400 over GPIB via VISA
% - key: VISA object returned for communication to/from Keithley
% This function only needs to be called once, and the same VISA object can
% then be referenced in all future key_**** function calls 
    key = visa('agilent','GPIB24::23::INSTR');
    key.InputBufferSize = 20000;   % set input buffer
    key.OutputBufferSize = 20000;  % set output buffer
    key.Timeout=10; % set maximum waiting time [s]  
    fopen(key); % open communication channel
    disp(query(key, '*IDN?')); % enquires equipment info
end

