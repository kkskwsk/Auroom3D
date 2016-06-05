function sizeInPixels = calcSizeInPixels(meters)
    global pixel2meterRatio;
    sizeInPixels = meters * pixel2meterRatio;
end