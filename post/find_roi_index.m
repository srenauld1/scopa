function [roi_index, roi_index_str] = find_roi_index(labsp)

varind_with_rois = find(startsWith(labsp, 'ts.resp') | startsWith(labsp, ' ts.resp')); %only check labels beginning with 'resp'
for li = 1:numel(labsp)
    if ismember(li, varind_with_rois) %if none begin with 'resp', then there is no roi data
        roi_index_expression = 'ind\d+$'; %ends with ind followed by integer
        [futmp, ~] = regexp(labsp{li}, roi_index_expression, 'match');
        if isempty(futmp) %single responses don't get 'ind1' suffix, but if string begins with resp, we can call it roi_index 1
            roi_index{li} = 1;
        else
            roi_index{li} = sscanf(cell2mat(futmp), 'ind%d'); %extract number at end, following 'ind'
        end
    else
        roi_index{li} = [];
    end
end

delim = ',';
roi_index_str = regexprep( mat2str(cell2mat(roi_index(~cellfun('isempty',roi_index)))), {'\[', '\]', '\s+'}, {'', '', delim});


end