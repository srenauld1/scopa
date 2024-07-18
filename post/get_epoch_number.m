function [epochs, fieldname_out] = get_epoch_number(varargin)

% numeric code for stimulus epochs

epochs.closedinitiallight = 1;
epochs.openslow = 2;
epochs.openfast = 3;
epochs.closedinterleave = 4;
epochs.dark = 5;
epochs.closedfinaldark = 6;

if ~isempty(varargin)
    if ischar(varargin{1})
        enumin = str2double(varargin{1});
    else
        enumin = varargin{1};
    end
    index = find(structfun(@(x) x==enumin,epochs));
    fns = fieldnames(epochs);
    fieldname_out = fns{index};
end

end