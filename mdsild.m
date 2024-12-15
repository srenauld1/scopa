function md = mdsild(pthmd, optsld, optsldhr, opt)

arguments
    pthmd
    optsld = []
    optsldhr = []
    opt.pthstack = []
end
pthstack = opt.pthstack;

if isempty(pthmd)
    if isempty(pthstack)
        error("must pass pthmd or pthstack")
    else
        id = idmake(pthstack); 
        pthmd = [id.dirstack id.recid '_mdsi_.txt'];
    end
end

if isempty(optsld)
    otmp = odf([], 'sld');
    optsld = otmp.sld;
end
if isempty(optsldhr)
    otmp = odf([], 'sld');
    optsldhr = otmp.sld;
end

if isfile(pthmd)
    md = structtxtld(pthmd);
else
    error("pthmd (mdsild.txt) does not exist; you need to run registration; there, mdsild.txt will be created from the raw scanimage output file")
end

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
    md = rmfield(md, 'md_hires');
end


md = cell2struct(cellfun(@double,struct2cell(md),'uni',false),fieldnames(md),1); %make everything double bc python made uint64

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
md.sampper = 1/md.volrate;
md.numvol = "renamed 'numvol_o' to distinguish from optional 'numvol_crop' which may or may not be different from 'numvol_o', depending on values of 'md.tcrop'";

md = structsort(md, vectype='row');

end



