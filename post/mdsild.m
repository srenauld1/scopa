function md = mdsild(pth_md, optld, optld_hires)

arguments
    pth_md
    optld = []
    optld_hires = []
end

if isempty(optld)
    optld = default_ld_opts();
end
if isempty(optld_hires)
    optld_hires = default_ld_opts();
end

md = readmdsi(pth_md); %function for converting scanimage metadata dict written to txt file by json in read_save_metadata.py

md.numvol_o = md.numvol;
md.sz_o = [md.ypix md.xpix md.numslice md.numvol_o];
md.numvol_crop = md.numvol_o - optld.tcropfront - optld.tcropback;
md.sz_crop = [md.sz_o(1) md.sz_o(2) md.sz_o(3) md.numvol_crop];
md.tcropfront = optld.tcropfront; %copy from struct ld
md.tcropback = optld.tcropfront; %copy from struct ld
md.crop_flyback = optld.crop_flyback; %copy from struct ld
md.zero_stack = optld.zero_stack; %copy from struct ld


if ~isfield(md,'channel_save')
    md.channel_save = 1;
end
if ~isfield(md,'channel_active')
    md.channel_active = 1;
end


if isfield(md,'md_hires')
    md.md_hires.sz_o = [md.md_hires.ypix md.md_hires.xpix md.md_hires.numslice md.md_hires.numvol];
    md.md_hires.tcropfront = 0;
    md.md_hires.tcropback = 0;
    md.md_hires.crop_flyback = optld_hires.crop_flyback;
    md.md_hires.zero_stack = optld_hires.zero_stack;
    hires_struct_tmp = cell2struct(cellfun(@double,struct2cell(md.md_hires),'uni',false),fieldnames(md.md_hires),1); %make everything double bc python made uint64
    if ~isfield(hires_struct_tmp,'zwid')%do this after conversion to double
        sprintf("zwid_hires NOT IN mdsi, COMPUTING/ADDING IT NOW")
        hires_struct_tmp.zwid = hires_struct_tmp.zfov / hires_struct_tmp.numslice;
    end
    if ~isfield(hires_struct_tmp,'zstartpos')%do this after conversion to double
        tmp = 0:hires_struct_tmp.zwid:hires_struct_tmp.zfov;
        hires_struct_tmp.zstartpos = tmp(1:end-1);
        if isempty(hires_struct_tmp.zstartpos)
            hires_struct_tmp.zstartpos = 0;
        end
    end
    md = rmfield(md, 'md_hires');
else
    hires_struct_tmp = [];
end


md = cell2struct(cellfun(@double,struct2cell(md),'uni',false),fieldnames(md),1); %make everything double bc python made uint64
md.md_hires = hires_struct_tmp;

if ~isfield(md,'xwid')%do this after conversion to double
    sprintf("xwid NOT IN mdsi, COMPUTING/ADDING IT NOW")
    md.xwid = md.xfov / md.xpix;
end
if ~isfield(md,'ywid')%do this after conversion to double
    sprintf("ywid NOT IN mdsi, COMPUTING/ADDING IT NOW")
    md.ywid = md.yfov / md.ypix;
end
if ~isfield(md,'zwid')%do this after conversion to double
    sprintf("zwid NOT IN mdsi, COMPUTING/ADDING IT NOW")
    md.zwid = md.zfov / md.numslice;
end
if ~isfield(md,'zstartpos')%do this after conversion to double
    tmp = 0:md.zwid:md.zfov;
    md.zstartpos = tmp(1:end-1);
    if isempty(md.zstartpos)
        md.zstartpos = 0;
    end
end

md.imper = 1/md.volrate;

md.numvol = "renamed 'numvol_o' to distinguish from optional 'numvol_crop' which may or may not be different from 'numvol_o', depending on values of 'md.tcropfront' and 'md.tcropback'";

md = orderfields_recursive(md);

end



function md = readmdsi(pth_md)
str = fileread(pth_md);
if startsWith(str, '{') && endsWith(str, '}')
    str = str(2:end-1);
    if endsWith(str, '}')
        str = str(1:end-1);
        if endsWith(str, '}')
            error("only written for one nested dict/struct, which is for md_hires; if you want more nesting need to repeat above for each layer")
        end
        str = strsplit(str, '{');
    else
        str = {str};
    end
end
for m = 1:numel(str)
    ts = str{m};
    ts = strsplit(ts, ', "');
    ts = erase(ts, {'{', '}', '"', ':'});
    tsn = regexp(ts, '[+-]?\d+\.?\d*', 'match');
    tss = regexp(ts, '[A-Z_a-z]*', 'match');
    for k = 1:numel(tss)
        if m==1
            md.(tss{k}{1}) = str2double(tsn{k});
        elseif m==2
            md.md_hires.(tss{k}{1}) = str2double(tsn{k});
        end
    end
end
end
