function pthsv = makepthsv(pthsv)

vnm = inputname(1);

callstack = dbstack('-completenames');
if numel(callstack) >= 2
   fcnnm = callstack(2).file;
else
   fcnnm = 'unknown function';
end

if isempty(pthsv)
    pthfldr = globals_a2p('pthfldr');
    if isempty(pthfldr)
        error(sprintf("global variable pthfldr has not been set, and " + vnm + " was not passed as argument into function " + newline + fcnnm + newline + "do one or the other"))
    end
    pthsv = [pthfldr char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')) fnsuffix];
end

end