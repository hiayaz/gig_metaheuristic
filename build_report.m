function results = build_report(best, I,J,T,cap,revenue,maxDur,demand,cpuSec,maxIter)
    results = struct();
    results.I = I; results.J = J; results.T = T;
    results.ObjectiveValue = best.profit;
    results.UpperBound = best.profit;
    results.IsOptimum = 0;
    results.Number_of_Iteration = maxIter;
    results.CPU_Second = cpuSec;
    results.assign = best.assign; results.open = best.open;
    results.revenue = revenue; results.maxDur = maxDur;
    results.cap = cap; results.demand = demand;
end