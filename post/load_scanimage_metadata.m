function md = load_scanimage_metadata(pth_md, optld, optld_hires)


md = struct2cell(load(pth_md)); %file created in initial 'pre' pipeline
md = md{1};

md.numvol_o = md.numvol;
md.sz_o = [md.ypix md.xpix md.numslice md.numvol_o];
md.numvol_crop = md.numvol_o - optld.tcropfront - optld.tcropback;
md.sz_crop = [md.sz_o(1) md.sz_o(2) md.sz_o(3) md.numvol_crop];
md.tcropfront = optld.tcropfront; %copy from struct ld
md.tcropback = optld.tcropfront;%copy from struct ld
md.crop_flyback = optld.crop_flyback;%copy from struct ld
md.zero_stack = optld.zero_stack;%copy from struct ld


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
        sprintf("zwid_hires NOT IN METADATANEW, COMPUTING/ADDING IT NOW")
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
    sprintf("xwid NOT IN METADATANEW, COMPUTING/ADDING IT NOW")
    md.xwid = md.xfov / md.xpix;
end
if ~isfield(md,'ywid')%do this after conversion to double
    sprintf("ywid NOT IN METADATANEW, COMPUTING/ADDING IT NOW")
    md.ywid = md.yfov / md.ypix;
end
if ~isfield(md,'zwid')%do this after conversion to double
    sprintf("zwid NOT IN METADATANEW, COMPUTING/ADDING IT NOW")
    md.zwid = md.zfov / md.numslice;
end
if ~isfield(md,'zstartpos')%do this after conversion to double
    tmp = 0:md.zwid:md.zfov;
    md.zstartpos = tmp(1:end-1);
    if isempty(md.zstartpos)
        md.zstartpos = 0;
    end
end

md.dtmni = 1/md.volrate;

md.numvol = "renamed 'numvol_o' to distinguish from optional 'numvol_crop' which may or may not be different from 'numvol_o', depending on values of 'md.tcropfront' and 'md.tcropback'";

md = orderfields_recursive(md);

