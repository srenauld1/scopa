function out = mdl_binld(pth, colinds)

%read model variable written to bin; colinds are sample inds; purpose is to
%prevent memory spikes by reading into memory only the necessary subsets of
%the data (since mdlmake often fits multiple modelsto different subsets of
%indv/depv
%colinds are the sample indices to be read (here called colinds, ie
%column indices)

arguments
    pth
    colinds = []
end

spl = strsplit(pth, '_');

numrow = str2double(spl{end-3});
numcol = str2double(spl{end-2});
full_size = [numrow numcol];

if nargin==2 && isempty(colinds)

    out = zeros(numrow,0);

else

    if nargin==1
        colinds = 1:numcol; %read all columns if single argument 
    end

    vclass = spl{end-4};

    bytespersamp = bps(vclass);

    switch vclass
        case {'int64', 'uint64', 'double'}
            bytespersamp = 8;
        case {'int32', 'uint32', 'single'}
            bytespersamp = 4;
        case {'int16', 'uint16'}
            bytespersamp = 2;
        case {'int8', 'uint8'}
            bytespersamp = 1;
    end

    bytespercol = numrow*bytespersamp;

    fid = fopen(pth, 'r');

    numcolread = numel(colinds);
    out = zeros(numcolread*numrow, 1, vclass);
    k = 0;
    while true
        k = k+1;
        idxbinstart = (colinds(k)-1) * bytespercol;
        fseek(fid, idxbinstart, 'bof');
        idxmat = [1:numrow] + numrow*(k-1);
        out(idxmat) = fread(fid, numrow, [vclass '=>' vclass]); %read depv then crop, to prevent broadcasting in parfor loop below
        if k==numel(colinds)
            break;
        end
    end

    fclose(fid);
    
    out = reshape(out, numrow, numcolread);

    % %multibandread is much slower than fread loop above, at least for the arrays with shape/size/order similar to indvpaug 
    % out2 = multibandread(pth, [numrow numcolread 1], [vclass '=>' vclass], 0, "bsq", "ieee-le", {"Column", "Direct", colinds});
    % out2 = out2'; %this should be equal to out

end


%%
