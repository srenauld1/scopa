function chopt = fnet_chopt(ver)

arguments
    ver = 1 % version
end

% expressions for parsing fnet mdlname string in mfit_parse_mdlname_string

switch ver
    case 1
        chopt.lay = {'[A-Z]{1}'}; %layer is any single capital letter
        chopt.chan = {'^(0*\d{1,2})*(0*\d{1,2}-\d+)*$'}; %channel is zero or more two-digit numbers, with optional hyphens denoting ranges; no channel means all channels
        chopt.comb = {'x'}; %a single x
        chopt.prefix = {'^x*0*\d*(?=\D)'}; %optional x followed by optional 2-digit number
        chopt.unit = {'^x*\d*((\D)*(h\d+)*(\D)*)+$'}; %optional x followed by optional 2-digit number, followed by one or more non-numeric character or one-hot encoding substring;
        chopt.lin = {'s','r','d','c','f'}; %linear functions;
        chopt.non = {'e','i','l','g','v'}; %nonlinear functions;
        chopt.hot = {'h\d+'}; %one-hot encoding function; h followed by one or more numeric characters
end
