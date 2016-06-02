sourceDirectoriesToAdd = [{'../dsp'}, {'../dsp/air'}, {'../dsp/directivity'}, {'../geometry'}, {'../scene'}, {'../scene/room'}, {'../scene/transducer'}, {'../scene/transducer/receiver'}, {'../scene/transducer/source'}, {'../simulation'}, {'../utils'}];
multimediaDirectoriesToAdd = [{'../../../multimedia/used'}, {'../../../doc/hrtf/MIT KEMAR/full/elev0'}];
hrtfPattern = '../../../doc/hrtf/MIT KEMAR/full/elev%d';
for i = -40:10:90
    addpath(sprintf(hrtfPattern, i));
end

global directoriesToAdd;
directoriesToAdd = cat(2, sourceDirectoriesToAdd, multimediaDirectoriesToAdd);

for i = 1:length(directoriesToAdd)
    addpath(directoriesToAdd{i});
end