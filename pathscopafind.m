function pthscopa = pathscopafind()

stk = dbstack('-completenames');
[pthenv, ~, ~] = fileparts(stk(1).file);
spl = strsplit(pthenv, filesep);
pthscopa = [strjoin(spl(1:find(~cellfun(@isempty, strfind(spl, 'scopa')))), filesep) filesep];

end
