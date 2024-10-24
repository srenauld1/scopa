function num = strnum(str)

%work in progress but works for most cases; extract numbers from char; will not work if decimal is not preceded by number (ie .5 is read as 5)

num = regexp(str,'(-)?\d+(\.\d+)?(e(-|+)\d+)?','match');

end