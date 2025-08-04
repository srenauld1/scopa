function odel(opt)

arguments
    opt.pthparent = []
    opt.ided_vbin = []
    opt.fig = 0
end
opt = glboropt(opt);
pthparent = opt.pthparent;
ided_vbin = opt.ided_vbin;
fig = opt.fig;

if fig

    inf = "figure";

    allvbin = {'gif', 'fig'};

    tmp2 = [];
    for k = 1:numel(allvbin)
        tmp = [pthparent '**' filesep '*.' allvbin{k}];
        tmp = rdir(tmp);
        tmp2 = vertcat(tmp2, tmp);
    end

    tmp2 = natsortfiles(tmp2);


    pthall = cell(1, numel(tmp2));
    for k = 1:numel(tmp2)
        pthall{k} = tmp2(k).name;
    end


else

    % delete all options files; run this to restart optid/varid numbering

    inf = "option";
    pthscopa = pathscopaget;
    scopausername = userdatfile('scopausername');
    if isempty(scopausername)
        error("you have not set glb('scopausername')")
    end
    if isempty(ided_vbin)
        error("ided_vbin must be defined in glb or passed in as name-value argument")
    end
    if isstring(ided_vbin)
        ided_vbin = convertStringsToChars(ided_vbin);
    end

    allvbin = [ided_vbin {'var', 'rg', 'mm'}];


    tmp2 = [];
    for k = 1:numel(allvbin)
        tmp = [pthscopa 'opt_' allvbin{k} '_' scopausername '_*_.txt'];
        tmp = rdir(tmp);
        tmp2 = vertcat(tmp2, tmp);
        tmp = [pthparent '**' filesep '*_' allvbin{k} '_.mat'];
        tmp = rdir(tmp);
        tmp2 = vertcat(tmp2, tmp);
    end

    tmp2 = natsortfiles(tmp2);


    pthall = cell(1, numel(tmp2));
    for k = 1:numel(tmp2)
        pthall{k} = tmp2(k).name;
    end


end


if isempty(pthall)

    fprintf("there are no " + inf + " files to delete" + newline)

else

    prompt = "\n\n\n" + sprintf('%s \n', pthall{:}) + newline + "PRESS 1 TO DELETE THE ABOVE FILES, 0 TO DELETE NOTHING: ";

    commandwindow();
    dodel = input(sprintf(prompt));

    if dodel
        delete(pthall{:})
    end

end