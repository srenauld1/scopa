function odel(opt)

arguments
    opt.pthpar = []
    opt.obin_ided = []
    opt.fig = 0
end
opt = glboropt(opt);
pthpar = opt.pthpar;
obin_ided = opt.obin_ided;
fig = opt.fig;

if fig

    inf = "figure";

    allobin = {'gif', 'fig'};

    tmp2 = [];
    for k = 1:numel(allobin)
        tmp = [pthpar '**' filesep '*.' allobin{k}];
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
    pthscopa = pthscopaget;
    scopausername = userdatfile('scopausername');
    if isempty(scopausername)
        error("you have not set glb('scopausername')")
    end
    if isempty(obin_ided)
        error("obin_ided must be defined in glb or passed in as name-value argument")
    end
    if isstring(obin_ided)
        obin_ided = convertStringsToChars(obin_ided);
    end

    allobin = [obin_ided {'var', 'rg', 'mm'}];


    tmp2 = [];
    for k = 1:numel(allobin)
        tmp = [pthscopa 'opt_' allobin{k} '_' scopausername '_*_.txt'];
        tmp = rdir(tmp);
        tmp2 = vertcat(tmp2, tmp);
        tmp = [pthpar '**' filesep '*_' allobin{k} '_.mat'];
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