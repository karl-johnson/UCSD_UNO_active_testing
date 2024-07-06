function anr = start_anritsu()
    anr = visa('agilent','GPIB1::29::INSTR');
    anr.InputBufferSize = 1e6;   % set input buffer
    anr.OutputBufferSize = 1e6;  % set output buffer
    anr.Timeout=10; % set maximum waiting time [s]  
    fopen(anr); % open communication channel
    disp(query(anr, '*IDN?')); % enquires equipment info
end

