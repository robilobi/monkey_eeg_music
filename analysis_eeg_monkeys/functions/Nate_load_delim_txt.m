function [S,var_names] = Nate_load_delim_txt(fl,delim,headers_to_load)
% Load data from a text-based file where items in a row are delimited by
% the string 'delim'. The first row of the file should contain the header
% names.
% Inputs:
% - fl = filename
% - delim = string of the delimiter in each row
% - headers_to_load = cell array of headers (strings) corresponding to
% columns to load (case sensitive)
% Outputs:
% - S = structure containing all of the data, each variable is named based
% on the headers_to_load
% Nate Zuk

% Open the file
fid = fopen(fl);

% The first line contains the headers for each column in the CSV
all_headers = fgetl(fid);

% Check each header, and find the ones that should be loaded
% get indexes where commas occur, and include the start (0) and the end of
% the all_headers string, for indexing later
comma_delims = [0 strfind(all_headers,delim) length(all_headers)+1];
header_idx = NaN(length(headers_to_load),1);
for ii = 2:length(comma_delims)
    h_select = (comma_delims(ii-1)+1):(comma_delims(ii)-1);
    header_cmp = cellfun(@(x) strcmp(all_headers(h_select),x), headers_to_load);
    if any(header_cmp) % if the current header matches any that should be loaded
        header_idx(header_cmp) = ii; % save the comma that occurs after the header
    end
end

% Name variables based on headers
var_names = cell(length(headers_to_load),1);
for ii = 1:length(headers_to_load)
    % get the header string
    hd = headers_to_load{ii};
    % replace any problematic characters with underscores
    problem_idx = [strfind(hd,'.') strfind(hd,'-')];
    hd(problem_idx) = '_';
    var_names{ii} = hd;
end

% Setup the structure containing all variables
S = struct;
for ii = 1:length(header_idx)
    eval(sprintf('S.%s = {};',var_names{ii}));
end

% Now go through each line and save the values corresponding to the
% headers to load
while 1
    rw = fgetl(fid);
    % check if we've reached the end of the CSV
    if ~ischar(rw) || contains(rw,'END OF FILE'), break, end
    % otherwise, load the values
    sep = [0 strfind(rw,delim) length(rw)+1]; % get placement of commas
    for n = 1:length(header_idx)
        % get indexes where the value for that column is stored
        try
            val_select = (sep(header_idx(n)-1)+1):(sep(header_idx(n))-1);
        catch err
            keyboard;
        end
        % save the value
        eval(sprintf('S.%s = [S.%s; {rw(val_select)}];',var_names{n},var_names{n}));
    end
end

% Close the file
fclose(fid);