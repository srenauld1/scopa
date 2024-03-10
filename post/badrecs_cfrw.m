
%recids to be exlucded
%different outer cells for different classes of exclusion 

%% for dataset one, 5 Hz, PB, GA, NO, syt7f, dates 20230609 to 20230627

badrecid{1} = { %these were different, or had technical issue 
    '20230613_4_1', ... %high res PB only
    '20230620_1_1', ... %phase mis-offset
    '20230620_1_2', ... %phase mis-offset
    '20230620_2_1', ... %phase mis-offset
    };

%after those 4 removed, that leaves 28 recordings in /n/files/Neurobio/wilsonlab/wienecke/stacks (dates 20230609 to 20230627)

badrecid{2} = { %these aren't very pretty after analysis (ugly bumps)
    '20230609_3_1', ... 
    '20230610_3_2', ... 
    '20230613_1_1', ... 
    '20230627_3_1', ... 
    };

%after these 4 removed, that leaves 24 recordings for that dataset 

%% for dataset two, 10 Hz (double previous), EB, GA, NO, syt7f, lower spatial res, zoomed in more, higher z res dates 20231119 to present 

%nothing to exclude yet
%at first glance, 20231119_1_1, 20231119_2_1, 20231119_3_1 are all good
    % 20231126_1_1 has bad evernote notes 
%there's one GLNO only recording with 7f (not syt7f) 20231120_3_1
%there are MITO-7f flies 20231120_1_1 and 20231120_2_1
