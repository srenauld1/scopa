function [inds, inds_str] = make_plot_inds(indsall, indsin, label_prefix, max_num_inds_to_print, strdelim)

arguments
    indsall {mustBeNumeric}
    indsin {mustBeNumeric} = []
    label_prefix char = ''
    max_num_inds_to_print = 20
    strdelim = '-';
end

if isscalar(indsall)
    indsall = 1:indsall;
end

if any(indsin<0) & numel(indsin)>1
    error("negative inds must be scalar")
end

fractional_indsin = 0;

if isempty(indsin)
    inds_str = ['1to' num2str(numel(indsall))];
    inds = 1:numel(indsall);
elseif indsin<0
    inds_str = ['neg' num2str(indsin)];
    if mod(indsin, 1)~=0
        error("negative inds must be integer")
    end
    if -indsin<numel(indsall)
        inds = round(linspace(1, numel(indsall), -indsin));
    else
        inds = 1:numel(indsall);
    end
elseif mod(indsin, 1)~=0
    fractional_indsin = 1;
    if numel(indsin)>1 || indsin<0
        error("fractional inds must be positive scalar")
    end
    seglength = fix(indsin);
    factmp = 10^(numel(num2str(indsin))-numel(num2str(seglength))-1);
    numseg = mod(indsin, 1)*factmp;
    numseg = round(numseg);
    segspacing = floor(numel(indsall)/numseg);
    inds = [1:seglength]+segspacing*([1:numseg]'-1)+segspacing-seglength;
    for j = 1:size(inds,1)
        inds_str{j} = [num2str(inds(j,1)) 'to' num2str(inds(j,end))];
    end
    inds_str = strjoin(inds_str, '-');
    inds = vec(inds.');
    if numel(inds)>numel(indsall) | any(inds<0)
        disp("warning, seglength*numseg exceeds num inds, plotting all inds")
        inds = 1:numel(indsall);
    end
else
    inds = indsin;
end

inds = inds(:)';

%regardless of what happens above, apply this as an additional step
if isequal(inds, min(inds):max(inds))
    inds_str = [num2str(min(inds)) 'to' num2str(max(inds))];
elseif isequal(sort(inds), min(inds):max(inds))
    inds_str = [num2str(min(inds)) 'to' num2str(max(inds)) 'unsorted'];
else
    if ~fractional_indsin
        if numel(inds)<max_num_inds_to_print
            inds_str = regexprep( mat2str(inds), {'\[', '\]', '\s+'}, {'', '', strdelim});
        else
            inds_str = 'noprint';
        end
    end
end

if~isempty(label_prefix)
    inds_str = [label_prefix strdelim inds_str];
end


end