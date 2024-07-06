function [xData,yData] = anr_get_trace(anr,traceLetter)
    % get traces captured on OSA
    % these are not in storage, but are on screen
    validLetters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"];
    % TODO check if letter is valid and make command string
    xCommand = sprintf('DC%s?', traceLetter);
    yCommand = sprintf('DB%s?', traceLetter);
    xQuery = query(anr, xCommand);
    xQuerySplit = split(xQuery, ',');
    xMin = str2double(xQuerySplit(1));
    xMax = str2double(xQuerySplit(2));
    xNum = str2double(xQuerySplit(3));
    xData = linspace(xMin, xMax, xNum);
    %xData = getChannelResults(anr, xCommand);
    yData = getChannelResults(anr, yCommand);

    function readingArray = getChannelResults(anr, command)
        % similar algorithm as agilent logging to download this
        queryResult = query(anr, command);
        if(char(queryResult(1)) ~= '#') %
            error("Logging result did not start with a #:" + queryResult);
        end
        % number of digits in following number of bytes
        numDigits = str2num(queryResult(2));
        % number of bytes comprising result
        numBytes = str2num(queryResult(3:3+numDigits-1));
        % now, we can do an fread to get those bytes - can't do a query as some
        % of the bytes may be same as EOF which ends query
        % must add a few bytes to the beginning since the beginning of the
        % buffer has that stuff we just used above
        extraBytes = 2 + numDigits;
        % now, have to use fwrite for bin data because EOF can happen in
        % binary data
        totNumBytes = extraBytes+numBytes;
        fwrite(anr,command);
        dataIn = fread(anr,totNumBytes,'uint8');
        bytesPerReading = 8;
        numReadings = numBytes/bytesPerReading;
        readingArray = zeros(1,numReadings);
        for readingIdx = 1:numReadings
            byteIdx = extraBytes+bytesPerReading*(readingIdx-1);
            theseBytes = dataIn(byteIdx+1:byteIdx+bytesPerReading);
            readingArray(readingIdx) = typecast(uint8(theseBytes), 'double');
        end
    end
end

