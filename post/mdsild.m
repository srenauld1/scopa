function md = mdsild(pth_md, optsld, optsldhr)

arguments
    pth_md
    optsld = []
    optsldhr = []
end

if isempty(optsld)
    optsld = odf('sld');
end
if isempty(optsldhr)
    optsldhr = odf('sld');
end

md = jsondecode(fileread(pth_md)); %convert scanimage metadata dict written to txt file by json.dumps in read_save_metadata.py

md.numvol_o = md.numvol;
md.sz_o = [md.ypix md.xpix md.numslice md.numvol_o];
md.numvol_crop = md.numvol_o - optsld.tcrop(1) - optsld.tcrop(2);
md.sz_crop = [md.sz_o(1) md.sz_o(2) md.sz_o(3) md.numvol_crop];
md.tcrop = optsld.tcrop; %copy from struct ld
md.cropfb = optsld.cropfb; %copy from struct ld
md.zerostack = optsld.zerostack; %copy from struct ld


if ~isfield(md,'channel_save')
    md.channel_save = 1;
end
if ~isfield(md,'channel_active')
    md.channel_active = 1;
end


if isfield(md,'md_hires')
    md.md_hires.sz_o = [md.md_hires.ypix md.md_hires.xpix md.md_hires.numslice md.md_hires.numvol];
    md.md_hires.tcrop = [0 0];
    md.md_hires.cropfb = optsldhr.cropfb;
    md.md_hires.zerostack = optsldhr.zerostack;
    hires_struct_tmp = cell2struct(cellfun(@double,struct2cell(md.md_hires),'uni',false),fieldnames(md.md_hires),1); %make everything double bc python made uint64
    if ~isfield(hires_struct_tmp,'zwid')%do this after conversion to double
        fprintf("zwid_hires NOT IN mdsi, COMPUTING/ADDING IT NOW" + newline)
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
    fprintf("xwid NOT IN mdsi, COMPUTING/ADDING IT NOW" + newline)
    md.xwid = md.xfov / md.xpix;
end
if ~isfield(md,'ywid')%do this after conversion to double
    fprintf("ywid NOT IN mdsi, COMPUTING/ADDING IT NOW" + newline)
    md.ywid = md.yfov / md.ypix;
end
if ~isfield(md,'zwid')%do this after conversion to double
    fprintf("zwid NOT IN mdsi, COMPUTING/ADDING IT NOW" + newline)
    md.zwid = md.zfov / md.numslice;
end
if ~isfield(md,'zstartpos')%do this after conversion to double
    tmp = 0:md.zwid:md.zfov;
    md.zstartpos = tmp(1:end-1);
    if isempty(md.zstartpos)
        md.zstartpos = 0;
    end
end

md.widyxz = [md.ywid, md.xwid, md.zwid];
if isfield(md,'md_hires') && ~isempty(md.md_hires)
    md.md_hires.widyxz = [md.ywid, md.xwid, md.md_hires.zwid];
end

md.sampper = 1/md.volrate;

md.numvol = "renamed 'numvol_o' to distinguish from optional 'numvol_crop' which may or may not be different from 'numvol_o', depending on values of 'md.tcrop'";

md = fieldord(md);

end



