function pathenv = getpathenv()

stk = dbstack('-completenames');
[pathenv, ~, ~] = fileparts(stk(1).file);

end