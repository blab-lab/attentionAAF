function frames = secs2frames(display,secs)
%secs2frames(display,secs)
%converts time in seconds to frames by calling: 
%frames = round(secs*display.frameRate);
frames = round(secs*display.frameRate);