clear
close all;
% Initialize field names for the struct members
fieldNames = {'Name', 'NF', 'Gain', 'OIP3'};

% Initialize the queue as an empty cell array
global queue;
queue = {};

global Pin_min;
global Pin_max;
global Pin_step;

% Example of creating initial blocks
createBlock(fieldNames);

% Create a UI figure with grid layout for the queue rendering
global fig;
fig = uifigure('Name', 'RF Lineup Utility', 'Position', [100, 100, 700, 530], ...
               'Resize', 'off', ...           % Disable window resizing
               'WindowState', 'normal');      % Prevent maximization
mainGrid = uigridlayout(fig, [5, 1]);  % Adjusted to 4 rows for additional controls
mainGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'}; % Adjusted to make "Delete Block" row its own size
mainGrid.ColumnWidth = {'1x'};

% Create a scrollable grid layout for rendering the queue in the bottom row
scrollGrid = uigridlayout(mainGrid, [1, 1], 'Scrollable', 'on');
scrollGrid.Layout.Row = 1;
scrollGrid.Layout.Column = 1;
scrollGrid.RowHeight = {'fit'};
scrollGrid.ColumnWidth = {'fit'};

% Create a new grid layout for the Add Block and Read Fields buttons with specific column widths
buttonGrid = uigridlayout(mainGrid, [1, 2]);
buttonGrid.Layout.Row = 2;
buttonGrid.RowHeight = {'fit'};
buttonGrid.ColumnWidth = {'fit', 'fit'}; % Makes buttons take only as much space as they need

% Add "Add Block" button
addButton = uibutton(buttonGrid, ...
    'Text', 'Add Block', ...
    'ButtonPushedFcn', @(btn, event) addBlockCallback(scrollGrid, fieldNames));
addButton.Layout.Column = 1; % Position button in first column

% UI components for moving an element in the queue
movePanel = uipanel(mainGrid, 'Title', 'Move Block', 'FontWeight', 'bold');
movePanel.Layout.Row = 3;
moveGrid = uigridlayout(movePanel, [1, 5]);
moveGrid.ColumnWidth = {'fit', 'fit', 'fit', 'fit', 'fit'};

% Label and input for current index
uilabel(moveGrid, 'Text', 'Block Number to move:', 'HorizontalAlignment', 'right');
input1 = uieditfield(moveGrid, 'numeric');
input1.Layout.Column = 2;

% Label and input for new position
uilabel(moveGrid, 'Text', 'New Position:', 'HorizontalAlignment', 'right');
input2 = uieditfield(moveGrid, 'numeric');
input2.Layout.Column = 4;

% Button to move element
moveButton = uibutton(moveGrid, ...
    'Text', 'Move', ...
    'HorizontalAlignment', 'center', ... % Center-aligned to prevent stretching
    'ButtonPushedFcn', @(btn, event) moveElementCallback(scrollGrid, input1, input2, fieldNames));
moveButton.Layout.Column = 5;

% UI components for deleting an element in the queue
deletePanel = uipanel(mainGrid, 'Title', 'Delete Block', 'FontWeight', 'bold');
deletePanel.Layout.Row = 4;
deleteGrid = uigridlayout(deletePanel, [1, 3]);
deleteGrid.ColumnWidth = {'fit', 'fit', 'fit'};

% Label and input for delete index
uilabel(deleteGrid, 'Text', 'Block Number to Delete:', 'HorizontalAlignment', 'right');
deleteInput = uieditfield(deleteGrid, 'numeric');
deleteInput.Layout.Column = 2;

% Button to delete element
deleteButton = uibutton(deleteGrid, ...
    'Text', 'Delete', ...
    'ButtonPushedFcn', @(btn, event) deleteElementCallback(scrollGrid, deleteInput, fieldNames));
deleteButton.Layout.Column = 3;

% Start Pin
% UI components for Pin
PinPanel = uipanel(mainGrid, 'Title', 'Analyze', 'FontWeight', 'bold');
PinPanel.Layout.Row = 5;
PinGrid = uigridlayout(PinPanel, [1, 7]);
PinGrid.ColumnWidth = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};

% Label and input for Minimum Pin
uilabel(PinGrid, 'Text', 'Minimum Pin:', 'HorizontalAlignment', 'right');
minPinInput = uieditfield(PinGrid, 'numeric');
minPinInput.Layout.Column = 2;

% Label and input for Maximum Pin
uilabel(PinGrid, 'Text', 'Maximum Pin:', 'HorizontalAlignment', 'right');
maxPinInput = uieditfield(PinGrid, 'numeric');
maxPinInput.Layout.Column = 4;

% Label and input for Pin Step
uilabel(PinGrid, 'Text', 'Pin Step:', 'HorizontalAlignment', 'right');
stepPinInput = uieditfield(PinGrid, 'numeric');
stepPinInput.Layout.Column = 6;

% Button to Analyze
AnalyzeButton = uibutton(PinGrid, ...
    'Text', 'Analyze', ...
    'HorizontalAlignment', 'center', ... % Center-aligned to prevent stretching
    'ButtonPushedFcn', @(btn, event) analyzeCallback(scrollGrid, minPinInput, maxPinInput, stepPinInput, fieldNames));
AnalyzeButton.Layout.Column = 7;
% End Pin

% Initial render of the queue
renderQueue(scrollGrid, fieldNames);

% Callback function for "Add Block" button
function addBlockCallback(scrollGrid, fieldNames)
    % Use createBlock function to add a new empty block to the queue
    readFieldsCallback(scrollGrid, fieldNames);
    createBlock(fieldNames);

    % Clear the contents of scrollGrid only
    delete(scrollGrid.Children);

    % Re-render the queue in the scrollable grid layout
    global queue;
    renderQueue(scrollGrid, fieldNames);
end

function analyzeCallback(scrollGrid, minPinInput, maxPinInput, stepPinInput, fieldNames)
    readFieldsCallback(scrollGrid, fieldNames);
    
    global Pin_min;
    global Pin_max;
    global Pin_step;
    global queue;
    Pin_min = minPinInput.Value
    Pin_max = maxPinInput.Value
    Pin_step = stepPinInput.Value
    
    % Processing goes here
    
    Pin = Pin_min:Pin_step:Pin_max;
    NFs_dB = zeros(length(queue), length(Pin));
    Gains_dB = zeros(length(queue), length(Pin));
    OIP3s_dB = zeros(length(queue), length(Pin));
    
    for i = 1:length(queue)
        Gains_dB(i,:) = parseGain(queue{i}.Gain);
        if (queue{i}.NF == "auto")
            NFs_dB(i,:) = - Gains_dB(i,:);
        else
            NFs_dB(i,:) = parseGain(queue{i}.NF);
        end
        OIP3s_dB(i,:) = parseGain(queue{i}.OIP3);
    end
    
    % Cascade Analysis
    Gain_total = zeros(1, length(Pin));
    NF_total = zeros(1, length(Pin));
    IIP3_total = zeros(1, length(Pin));
    OIP3_total = zeros(1, length(Pin));

    for i = 1:length(Pin)
        NF_dB = NFs_dB(:,i)';
        Gain_dB = Gains_dB(:,i)';
        OIP3_dB = OIP3s_dB(:,i)';
        IIP3_dB = OIP3_dB - Gain_dB;

        NF_total_dB = 10*log10(NF_cascade(10.^(NF_dB/10), 10.^(Gain_dB/10)));
        GainTotal_dB = sum(Gain_dB);
        IIP3_total_dB = 20*log10(IIP3_cascade(10.^(IIP3_dB/20), 10.^(Gain_dB/20)));
        OIP3_total_dB = IIP3_total_dB + GainTotal_dB;

        Gain_total(i) = GainTotal_dB;
        NF_total(i) = NF_total_dB;
        IIP3_total(i) = IIP3_total_dB;
        OIP3_total(i) = OIP3_total_dB;
    end
    
    SNR = Pin - (-174 + NF_total + 10*log10(1e7));
    SDR = -2*(Pin - IIP3_total);
    SNDR = -10*log10(10.^(-SNR/10) + 10.^(-SDR/10));
    
    figure(1);
    plot(Pin, NF_total, 'LineWidth', 2);
    title("Total Cascaded NF, Gain, and Linearity Specs variation with Pin");
    hold on;
    grid on;
    plot(Pin, OIP3_total, 'LineWidth', 2);
    plot(Pin, IIP3_total, 'LineWidth', 2);
    plot(Pin, Gain_total, 'LineWidth', 2);
    legend(["NF", "OIP3", "IIP3", "Gain"]);
    xlabel("P_{in} (dB)");
    ylabel("Spec (dB)");
    hold off;

    figure(2);
    plot(Pin, SNR, 'LineWidth', 2);
    title("SNR, SDR and SNDR variation with Pin");
    hold on;
    grid on;
    plot(Pin, SDR, 'LineWidth', 2);
    plot(Pin, SNDR, 'LineWidth', 2);
    legend(["SNR", "SDR", "SNDR"]);
    xlabel("P_{in} (dB)");
    ylabel("Spec (dB)");
    hold off;
    
    % Remove Later
    figure(3);
    subplot(3, 1, 1);
    plot(Pin, Gains_dB(3,:) + Gains_dB(4,:), 'LineWidth', 2);
    title("Gain Policy (VGAs Gains variation with Pin)");
    grid on;
    legend("VGA 1");
    xlabel("P_{in} (dB)");
    ylabel("Gain (dB)");
    subplot(3, 1, 2);
    plot(Pin, Gains_dB(7,:) + Gains_dB(8,:), 'LineWidth', 2);
    grid on;
    legend("VGA 2");
    xlabel("P_{in} (dB)");
    ylabel("Gain (dB)");
    subplot(3, 1, 3);
    plot(Pin, Gains_dB(9,:) + Gains_dB(10,:), 'LineWidth', 2);
    grid on;
    legend("VGA 3");
    xlabel("P_{in} (dB)");
    ylabel("Gain (dB)");
    
    figure(4);
    title("NF and IIP3 variations with Pin)");
    plot(Gain_total, NF_total, 'LineWidth', 2);
    hold on;
    grid on;
    plot(Gain_total, IIP3_total, 'LineWidth', 2);
    legend(["NF", "IIP3"]);
    xlabel("Gain (dB)");
    ylabel("Spec (dB)");
    hold off;
    
    figure(5);
    plot(Pin, Gain_total, 'LineWidth', 2);
    title("Gain variation with Pin");
    grid on;
    legend(["Gain"]);
    xlabel("P_{in} (dB)");
    ylabel("Gain (dB)");
    hold off;
    
    figure(6);
    plot(Pin, Pin+Gain_total, 'LineWidth', 2);
    title("Gain variation with Pin");
    grid on;
    legend(["Gain"]);
    xlabel("P_{in} (dB)");
    ylabel("Gain (dB)");
    hold off;
end

% Callback function to read fields and update queue
function readFieldsCallback(scrollGrid, fieldNames)
    global queue;
    for i = 1:length(queue)
        for j = 1:length(fieldNames)
            % Access each field using its stored editField handle
            editField = queue{i}.(['editField_' fieldNames{j}]);
            % Update the queue with the current value from the edit field
            queue{i}.(fieldNames{j}) = editField.Value;
        end
    end
    % Display updated queue (optional, for debugging)
    disp(queue);
end

% Callback function for "Move" button
function moveElementCallback(scrollGrid, input1, input2, fieldNames)
    readFieldsCallback(scrollGrid, fieldNames);
    global queue;
    global fig;
    currentIndex = input1.Value;
    newPosition = input2.Value;

    % Validate inputs
    try 
        % Call moveQueueElement function to move the element
        moveQueueElement(currentIndex, newPosition);
    catch e
        uialert(fig, 'Please enter valid indices for Current Index and New Position.', 'Input Error');
        return;
    end

    % Clear and re-render the queue in the scrollable grid layout
    delete(scrollGrid.Children);
    renderQueue(scrollGrid, fieldNames);
end

% Callback function for "Delete" button
function deleteElementCallback(scrollGrid, deleteInput, fieldNames)
    readFieldsCallback(scrollGrid, fieldNames);
    global queue;
    global fig;
    indexToDelete = deleteInput.Value;

    % Validate input
    try
        % Call deleteFromQueue function to delete the element
        deleteFromQueue(indexToDelete);
    catch e
        uialert(fig, 'Please enter a valid index to delete.', 'Input Error');
        return;
    end

    % Clear and re-render the queue in the scrollable grid layout
    delete(scrollGrid.Children);
    renderQueue(scrollGrid, fieldNames);
end

% Function to create a new block and push it to the queue
function createBlock(fieldNames)
    % Create a new struct with empty values
    newBlock = struct();
    for i = 1:length(fieldNames)
        newBlock.(fieldNames{i}) = '';  % Set all field values to empty
    end

    % Push the new block to the queue
    global queue;
    queue{end + 1} = newBlock;  % Use end + 1 to append to the cell array
end

% Function to render the queue in the scrollable panel
function renderQueue(parent, fieldNames)
    % Define layout settings for the panel
    global queue;
    numElements = length(queue);    % Number of queue elements
    numFields = length(fieldNames); % Number of fields per queue element
    elementWidth = 150;             % Width of each element block
    elementHeight = 30;             % Height of each input field/label
    blockSpacing = 20;              % Space between blocks
    borderSpacing = 5;              % Border spacing within each block

    % Create a grid layout for all blocks inside the scrollable panel
    grid = uigridlayout(parent, [1, numElements], 'Scrollable', 'on');
    grid.RowHeight = {'fit'};
    grid.ColumnWidth = repmat({elementWidth + borderSpacing * 2}, 1, numElements);
    grid.Padding = [10 10 10 10];
    grid.ColumnSpacing = blockSpacing;

    % Loop through each queue element and create bordered blocks with labels
    for i = 1:numElements
        % Outer bordered panel for each block
        blockPanel = uipanel(grid, ...
            'Title', sprintf('Block %d', i), ...
            'FontWeight', 'bold', ...
            'FontSize', 10);

        % Inner grid for labels and fields inside each block
        blockGrid = uigridlayout(blockPanel, [numFields, 2]); % 2 columns for label and field
        blockGrid.RowHeight = repmat({elementHeight}, 1, numFields);
        blockGrid.ColumnWidth = {'1x', '2x'};
        blockGrid.Padding = [borderSpacing, borderSpacing, borderSpacing, borderSpacing];

        % Add field name labels and corresponding input fields inside each block
        for j = 1:numFields
            % Label for each field inside the block
            fieldLabel = uilabel(blockGrid, ...
                'Text', fieldNames{j}, ...
                'HorizontalAlignment', 'right', ...
                'FontSize', 10);
            fieldLabel.Layout.Row = j;
            fieldLabel.Layout.Column = 1;

            % Editable input field for the struct's field value
            editField = uieditfield(blockGrid, 'text', ...
                'Value', queue{i}.(fieldNames{j}), ...
                'FontSize', 10);
            editField.Layout.Row = j;
            editField.Layout.Column = 2;

            % Store the editField handle in the queue struct for easy access
            queue{i}.(['editField_' fieldNames{j}]) = editField;
        end
    end
end

% Function to move a queue element to a new position
function moveQueueElement(currentIndex, newPosition)
    % Ensure the indices are within valid ranges
    global queue;
    if currentIndex < 1 || currentIndex > length(queue)
        error('Current index is out of range.');
    end
    
    newPosition = max(1, min(newPosition, length(queue)));

    % Remove the block from the current position
    blockToMove = queue{currentIndex};
    queue(currentIndex) = [];  % Remove block from current position

    % Insert the block at the new position
    queue = [queue(1:newPosition-1), {blockToMove}, queue(newPosition:end)];
end

% Function to delete an element from the queue at a specified index
function deleteFromQueue(index)
    global queue;

    % Ensure the index is within the valid range
    if index < 1 || index > length(queue)
        error('Index is out of range.');
    end

    % Remove the element at the specified index
    queue(index) = [];  % Deletes the specified element and adjusts the queue
end