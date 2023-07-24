function stim_names = get_stims_from_triggers(trig_vals)
% Get the stimulus names from the trigger values
% Triggers have values of 101-120
% 101-110 = original (audio01, audio02, etc.)
% 111-120 = shuffled (shf01, shf02, etc.)

stim_names = cell(length(trig_vals),1);
for n = 1:length(trig_vals)
    % remove the 100
    val = mod(trig_vals(n),100);
    % determined if shuffled
    shuf_flag = floor((val-1)/10);
    if shuf_flag
        fl_prefix = 'shf';
    else
        fl_prefix = 'audio';
    end
    % get the stimulus index (audio01, audio02, etc.)
    stim_idx = mod(val-1,10)+1;
    % get the stimulus name
    stim_names{n} = sprintf('%s%02g',fl_prefix,stim_idx);
end