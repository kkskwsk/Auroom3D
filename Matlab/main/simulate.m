function context = simulate(numberOfParticles, hrtf)
simulationContext = Simulation3dContext(numberOfParticles, hrtf);
simulationContext.start();
context = simulationContext;
end

