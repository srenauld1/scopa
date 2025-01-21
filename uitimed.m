function ui = uitimed(msg, waittime)

arguments
    msg
    waittime = 25;
end

ui = []; 
duration = 0; 

tic; 

while isempty(ui) && (duration < waittime)
    duration = toc; %exclude previous 1 ms
    ui = input(msg + newline);
    pause(0.001);
end

if isempty(ui)
    disp('Timeout!'); 
end
