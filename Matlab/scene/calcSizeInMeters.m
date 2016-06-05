function sizeInMeters = calcSizeInMeters(pixels)
    global pixel2meterRatio;
    meter2pixelRatio = 1/pixel2meterRatio;
    sizeInMeters = pixels * meter2pixelRatio;
end