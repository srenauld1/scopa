function o = oset(spec)

%{

oset is a wrapper for the following functions:
    --stackfind: find imaging stacks
    --oset_*: set options (can be stack-specific)
        --ofill: called from oset_* files; for any options unspecified in oset_*, ofill fills options struct with defaults (defined in odf.m) for all a2p modules (high-level functions with options under id-control)
            --oid: called from ofill when finalizing options struct; assign id to unique options sets, write to txt file; also distribute each element of any cell-valued options into separate options sets; also check for problems in options struct

**** NB: DO NOT USE CELLS FOR VALUES ASSIGNED TO OPTIONS IN OSET_* FILES, UNLESS YOU INTEND THEM FOR "DISTRIBUTION" IN OID ****

%}

arguments
    spec = [] % spec struct (see function stackfind), or char or cell of char specifying full path to stack(s); if the latter, can have wildcards *; if empty, will search for file using spec below;
end

%%%% RECORDING SPECIFIERS (USED TO FIND RECORDINGS IF THERE IS NO INPUT TO a2p) %%%%

if isempty(spec) %if you're running a2p without input arguments (ie if optional input 'spec' is empty), set specifiers here to find stack(s); any missing fields will get defaults in ofill; if spec is not empty, these specifiers are ignored
    spec.pthpat = {''}; %full path pattern, can have wildcards; if you use pth, you cannot use stackid, recdate, fly, trial, suffix, or substr (single wildcard * means 0 or more characters, but does not include file separators, or cross file separators; double wildcard ** means 0 or more folders, and must be between file separators);
    spec.stackid = {'20250920_1_3_ord'}; %char, format recdate_fly_trial_suffix; can include wildcards; can truncate full stackid format with wildcard * and wildcard * gets copied to each subsequent underscore-delimited label (eg, 2025* is equivalent to 2025*_*_*_*); cannot use stackid if any of pth, recdate, fly, trial, or suffix are nonempty
    spec.recdate = {''}; %cell array of char (or char vector), can use wildcards; empty is equivalent to '*'
    spec.fly = {''}; %cell array of char (or char vector), can use wildcards; empty is equivalent to '*'
    spec.trial = {''}; %cell ara2ray of char (or char vector), can use wildcards; empty is equivalent to '*'
    spec.suffix = {''}; %cell array of char (or char vector), can use wildcards, stack filename suffix to use; valid suffixes are defined in odf, d.spec.suffixchar_raw and d.spec.suffixchars; empty is equivalent to '*'
    spec.substr = {''}; %cell array of char (or char vector), can use wildcards, substring contained in path to stack (for example, if all recordings from one campaign are in a subfolder with a descriptive name, you could put that name here, and asterisks for recdate, fly, trial, and get all those recordings just with the substr); empty is equivalent to '*'
    spec.match = 'each'; %'any' or 'each'; 'any' for all combinations of recdate, fly, trial, suffix; 'each' for matched indices of each of these specifiers (length 1 will be repeated to match anything longer)
elseif istextall(spec)
    spectmp.pthpat = spec;
    spec = spectmp;
end

prs = struct2pairs(spec);
pthstacks = stackfind(prs{:}, err=1); % find stacks using spec; error if none found (err=1)
idtmp = idmake(pthstacks);


%%%% LOOP OVER FOUND STACKS IN idtmp, SETTING OPTIONS (IN oset_* FILES) SPECIFIC TO RECORDING AND SCOPAUSERNAME %%%%

for k = 1:numel(idtmp)
    clear ofill %clear persistent variables in ofill for each stack
    switch userdatfile('scopausername')
        case 'cw'
            if contains(idtmp(k).pthstack, {'ebgano'})
                o(k) = oset_ebgano();
            elseif contains(idtmp(k).pthstack, {'ganopb'})
                o(k) = oset_ganopb();
            elseif contains(idtmp(k).pthstack, {'elno'})
                o(k) = oset_elno();
            elseif contains(idtmp(k).pthstack, {'ebno'})
                o(k) = oset_ebno();
            elseif contains(idtmp(k).pthstack, {'opto'})
                o(k) = oset_opto();
            elseif contains(idtmp(k).pthstack, {'fb8c'})
                o(k) = oset_fb8c();
            elseif contains(idtmp(k).pthstack, {'mito'})
                o(k) = oset_mito();
            elseif contains(idtmp(k).pthstack, {'312'})
                o(k) = oset_312();
            elseif contains(idtmp(k).pthstack, {'f91g'})
                o(k) = oset_t5();
            end
        case 'wz'
            if contains(idtmp(k).pthstack, {''}) %empty char for no stack path filtering
                o(k) = oset_wenyi();
            end
        case 'jf'
            if contains(idtmp(k).pthstack, {''}) %empty char for no stack path filtering
                o(k) = oset_jingxuan();
            end
        case 'yz'
            if contains(idtmp(k).pthstack, {''}) %empty char for no stack path filtering
                o(k) = oset_yunzhi();
            end
        case 'sr'
            if contains(idtmp(k).pthstack, {''}) %empty char for no stack path filtering
                o(k) = oset_sophia();
            end
    end

end

for k = 1:numel(idtmp)
    o(k).id = idtmp(k); % put id into options struct (even if o is otherwise empty for that stack, so we see what didn't stacks enter any oset_* file)
end


end













