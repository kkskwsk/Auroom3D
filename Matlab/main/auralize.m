function auralize(simContext, filename)
[lef, ref] = simContext.getFilters();
Simulation3dContext.auralize(filename, lef, ref);
end

