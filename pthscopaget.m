function pthscopa = pthscopaget()

%get path to repository 'scopa'

stk = dbstack('-completenames');
pthenv = fileparts(stk(1).file); %location of this file
spl = strsplit(pthenv, filesep);
tmpk = find(strcmp(spl, 'scopa'), 1, 'last'); %last appearance of folder scopa (folder holding this file), in case you put scopa in folder(s) named scopa
pthscopa = [strjoin(spl(1:tmpk), filesep) filesep];

end
