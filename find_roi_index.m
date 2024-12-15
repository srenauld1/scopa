function [roiind, roi_index_str] = find_roi_index(labsp)

varind_with_rois = find(startsWith(labsp, 'resp')); %only check labels beginning with 'resp'
for li = 1:numel(labsp)
    if ismember(li, varind_with_rois) %if none begin with 'resp', then there is no roi data
        roi_index_expression = 'ind\d+$'; %ends with ind followed by integer
        [futmp, ~] = regexp(labsp{li}, roi_index_expression, 'match');
        if isempty(futmp) %single responses don't get 'ind1' suffix, but if string begins with resp, we can call it roiind 1
            roiind{li} = 1;
        else
            roiind{li} = sscanf(cell2mat(futmp), 'ind%d'); %extract number at end, following 'ind'
        end
    else
        roiind{li} = [];
    end
end

delim = ',';
roi_index_str = regexprep( mat2str(cell2mat(roiind(~cellfun('isempty',roiind)))), {'\[', '\]', '\s+'}, {'', '', delim});


end