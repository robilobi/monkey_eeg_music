function [S,var_names] = Nate_get_idyom_vars(stiminfo_fl,headers_to_load,numeric_flag)
% Extract the vector of IDyOM variables, and store each as separate
% variables in the S structure.
% Inputs:
% - stiminfo_fl = file containin the IDyOM variables
% - headers_to_load = cell array of headers to include when getting the
% data
% - numeric_flag = logical array indicating which variables (headers)
% should be converted into numeric arrays (1=convert, 0 otherwise; default
% = 0 all variables)
% Nate Zuk (2022)

if nargin < 3 
    numeric_flag = false(length(headers_to_load),1);
end

% Load the data from the file
[S,var_names] = Nate_load_delim_txt(stiminfo_fl,' ',headers_to_load);

% Convert arrays to numeric arrays if needed
convert_arrays = find(numeric_flag);
for n = 1:length(convert_arrays)
    eval(sprintf('cl = S.%s;',var_names{convert_arrays(n)}));
    ar = NaN(length(cl),1);
    for ii = 1:length(ar)
        ar(ii) = str2double(cl{ii});
    end
    eval(sprintf('S.%s = ar;',var_names{convert_arrays(n)}));
end