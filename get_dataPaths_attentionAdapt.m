function [dataPaths] = get_dataPaths_attentionAdapt()
% Get data paths for attentionAdapt expt.

svec = [222 249 289 423 425 426 428 429 430 433 434 435 436 438 ....
	439 448 449 452 401 454];
    

dataPaths = get_acoustLoadPaths('attentionAdapt',svec);

end
