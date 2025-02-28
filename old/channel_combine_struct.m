function respout = channel_combine_struct(resp)

if any(~cellfun(@isempty, regexp(fieldnames(resp), 'chn1$'))) && any(~cellfun(@isempty, regexp(fieldnames(resp), 'chn2$'))) %when fields were 2-chan, used this: numchan = max(cellfun(@(x) size(x,3), struct2cell(respin)));
    numchan = 2;
else
    numchan = 1;
end

if numchan==2
    for c = 1:numchan
        chanpat = ['_chn' num2str(c)]; %only use chan suffix for fieldname if there are two channels
        fn = fieldnames(resp);
        resptmp = struct2cell(resp);
        kp = contains(fn, chanpat); %can't do endsWith since ind subfield may follow norm subfield at ths point
        resptmp = resptmp(kp);
        fn = erase(fn(kp), chanpat);
        if c==1
            respout = cell2struct(resptmp, fn);
        elseif c==2
            resptmp = cell2struct(resptmp, fn);
            for k = 1:numel(fn)
                if isfield(respout, fn{k})
                    respout.(fn{k})(:,:,c) = resptmp.(fn{k});
                else
                    respout.(fn{k}) = resptmp.(fn{k});
                end
            end
        end
    end
end

end