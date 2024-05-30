function [ ] = gen_merged_fmtMatrices_crossSubj_attentionComp(dataPaths)
%GEN_MERGED_FMTMATRICES_NOISYFB  Batch script to merge across words in noisy feedback expt.

for s=1:length(dataPaths)
    dataPath = dataPaths{s};
    file2merge = gen_fmtMatrix_attentionComp(dataPath,[],0);
    %   file2merge = 'fmtMatrix_shiftIHbeddotsshiftIHbednodotsshiftIHdeaddotsshiftIHdeadnodotsshiftIHheaddotsshiftIHheadnodotsshiftAEbeddotsshiftAEbednodotsshiftAEdeaddotsshiftAEdeadnodotsshiftAEheaddotsshiftAEheadnodots_noShiftbednoShiftdeadnoShiftheadnoShiftbednoShiftdeadnoShifthead';
    merge_fmtMatrices(dataPath,file2merge,{...
        {'shiftIHheaddots' 'shiftIHbeddots' 'shiftIHdeaddots' 'shiftAEheaddots' 'shiftAEbeddots' 'shiftAEdeaddots'},...
        {'shiftIHheadnoDots' 'shiftIHbednoDots' 'shiftIHdeadnoDots' 'shiftAEheadnoDots' 'shiftAEbednoDots' 'shiftAEdeadnoDots'}},...
        {'dots' 'noDots'},0);
%    plot_fmtMatrix_attentionComp(dataPath,'fmtMatrix_shiftIHdotsshiftIHnodotsshiftAEdotsshiftAEnodots_merged','diff1'); axis([0 .3 -75 75])
end