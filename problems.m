

% if you get error "Invalid argument at position n. Function requires exactly 5-1 positional input(s)" check that you're not passing a nonscalar struct into a function (eg if you want to pass channel 1 roi weights, and there are two channels, pass roidat(1).roiwt, instead of roidat.roiwt)
