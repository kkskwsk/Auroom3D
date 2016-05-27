function sizeInMeters = calcSizeInMeters(pixels)
    meter2pixelRatio = 1/50; %200 px = 1 m
    sizeInMeters = pixels * meter2pixelRatio;
end