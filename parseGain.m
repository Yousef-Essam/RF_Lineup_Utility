function Gain_array = parse_gain_string(gainString)
    global Pin_min;
    global Pin_max;
    global Pin_step;
    % Split gainString by ';' to separate gain-Pin pairs
    gainPairs = strsplit(gainString, ';');
    
    % If there is only one value in gainString
    if length(gainPairs) == 1
        gainPin = strsplit(gainPairs{1}, ',');
        gain = str2double(gainPin{1});
        Gain_array = gain * ones(1, ceil((Pin_max - Pin_min) / Pin_step) + 1);
        return;
    end
    
    % Initialize arrays to store gain and Pin values
    numPairs = length(gainPairs);
    gains = zeros(1, numPairs);
    Pins = zeros(1, numPairs);
    
    % Parse gain and Pin values from gainString in a single loop
    for i = 1:numPairs
        gainPin = strsplit(gainPairs{i}, ',');
        gains(i) = str2double(gainPin{1});
        Pins(i) = str2double(gainPin{2});
    end
    
    % Define the Pin values for the full range and preallocate Gain_array
    Pin_vals = Pin_min:Pin_step:Pin_max;
    Gain_array = gains(1) * ones(1, length(Pin_vals));  % Initialize with gain1

    % Interpolate only for values within range
    inRange = Pin_vals >= Pins(1) & Pin_vals <= Pins(end);
    Gain_array(inRange) = interp1(Pins, gains, Pin_vals(inRange), 'linear');
    
    % Set the gain beyond the specified Pin range
    Gain_array(Pin_vals > Pins(end)) = gains(end);
end



% function Gain = parseGain(gainString)
%     global Pin_min;
%     global Pin_max;
%     global Pin_step;
%     
%     % Split and convert to numbers
%     a_values = str2double(split(gainString, {',', ';'}));
% 
%     % If there's only one element, append Pin_max to make it a 1x2 matrix
%     if numel(a_values) == 1
%         a = [a_values, Pin_max];
%     else
%         % Otherwise, reshape into two columns
%         a = reshape(a_values, [], 2);
%     end
%     
%     Gain = [];
%     
%     if (length(a) == 1)
%         Gain = linspace(a(1), a(1), (Pin_max - Pin_min)/Pin_step + 1);
%         return;
%     end
%     
%     Gain = linspace(a(1,1), a(1,1), (a(1,2) - Pin_min)/Pin_step + 1);
%     Gain = Gain(1:end-1);
%     
%     for i = 1:(length(a)-1)
%         Gain = [Gain linspace(a(i,1), a(i+1,1), (a(i+1,2) - a(i,2))/Pin_step + 1)];
%         Gain = Gain(1:end-1);
%     end
%     
%     Gain = [Gain linspace(a(end,1), a(end,1), (Pin_max - a(end,2))/Pin_step + 1)];
% end