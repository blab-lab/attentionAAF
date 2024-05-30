function [dataPaths] = get_dataPaths_attentionComp()
% Get data paths for attentionComp expt.

svec = [146 317 318 319 194 320 248 272 307 316 328 202 234 329 331....
    332 333 315 337 315 203 334 338 339 341 345]; %exclude 324 due to crash
dataPaths = get_acoustLoadPaths('attentionComp',svec);

end
