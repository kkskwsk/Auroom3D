function sizeInPixels = calcSizeInPixels(meters)
    pixel2meterRatio = 100/1; %200 px = 1 m
    sizeInPixels = meters * pixel2meterRatio;
end