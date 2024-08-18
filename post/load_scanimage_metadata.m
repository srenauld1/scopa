function md = load_scanimage_metadata(pth_md, optld, optld_hires)


md = struct2cell(load(pth_md)); %file created in initial 'pre' pipeline
md = md{1};

% ff = @(x,y) cell2struct([struct2cell(md);struct2cell(mdnew)],[fieldnames(md);fieldnames(mdnew)]);
% md = ff(md, mdnew);
md.numvol_o = md.numvol;
md.sz_o = [md.ypix md.xpix md.numslice md.numvol_o];
md.numvol_crop = md.numvol_o - optld.numsamp_crop_t_front - optld.numsamp_crop_t_back;
md.sz_crop = [md.sz_o(1) md.sz_o(2) md.sz_o(3) md.numvol_crop];
md.numsamp_crop_t_front = optld.numsamp_crop_t_front; %copy from struct ld
md.numsamp_crop_t_back = optld.numsamp_crop_t_front;%copy from struct ld
md.crop_flyback = optld.crop_flyback;%copy from struct ld
md.zero_stack = optld.zero_stack;%copy from struct ld

if ~isfield(md,'zstartpos')
    tmp = 0:md.zwid:md.zfov;
    md.zstartpos = tmp(1:end-1);
end

if isfield(md,'md_hires')
    md.md_hires.sz_o = [md.md_hires.ypix md.md_hires.xpix md.md_hires.numslice md.md_hires.numvol];
    md.md_hires.numsamp_crop_t_front = 0;
    md.md_hires.numsamp_crop_t_back = 0;
    md.md_hires.crop_flyback = optld_hires.crop_flyback;
    md.md_hires.zero_stack = optld_hires.zero_stack;
    hires_struct_tmp = cell2struct(cellfun(@double,struct2cell(md.md_hires),'uni',false),fieldnames(md.md_hires),1); %make everything double bc python made uint64
    md = rmfield(md, 'md_hires');
else
    hires_struct_tmp = [];
end
md = cell2struct(cellfun(@double,struct2cell(md),'uni',false),fieldnames(md),1); %make everything double bc python made uint64
md.md_hires = hires_struct_tmp;
md.xwid = md.xfov / md.xpix; %do this after conversion to double
% md.zwid = md.zfov / md.numslice; %do this after conversion to double

md.dtmni = 1/md.volrate;

md.numvol = "renamed 'numvol_o' to distinguish from optional 'numvol_crop' which may or may not be different from 'numvol_o', depending on values of 'md.numsamp_crop_t_front' and 'md.numsamp_crop_t_back'";


% md = load_flyg_metadata(ids, pth.flyg_md, pth.fldr, md); %commenting out bc a2p doens't use anything except ball_diameter, and flyg metadata file is created in flyg preprocessing pipeline, which you don't need to run if you're running scopa


md = orderfields(md);

