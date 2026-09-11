
% abc_gig_scheduling_strict.m
% ABC with strict capacity (no overtime), randomized construction,
% and freelancer-centric local search (block transfer / swap).
%
% Key changes vs. previous version:
%   - Capacity is a HARD constraint: total assigned periods for freelancer i
%     cannot exceed cap(i). No overtime is allowed (Experiment 1.2 consistency).
%   - Randomized greedy builder (GRASP-style RCL) avoids fixed ordering bias.
%   - Repair pass enforces contiguity (no return to the same project) by
%     keeping only the longest block and refilling deficits with others.
%   - New neighbor move: freelancer block transfer/swap.
%   - Optional warm start: if 'ExampleAssignment.xlsx' exists (rows=i, cols=t,
%     cell=project index or 0), it will be used to seed initial solutions.
%
% Usage:
%   results = abc_gig_scheduling_strict();
%
function results = abc_gig_scheduling_strict()

    rng(42);

    if isfile('input.xlsx')
        data = load_input_excel('input.xlsx');
    else
        warning('input.xlsx not found. Building demo dataset for 10 freelancers, 6 projects, 12 periods.');
        data = build_demo_data();
    end

    I = data.I; J = data.J; T = data.T;
    wage = data.wage; addWage = data.addWage; %#ok<NASGU>
    cap = data.cap(:)'; demand = data.demand; revenue = data.revenue(:)';
    maxDur = data.maxDur(:)'; startCost = data.startCost(:)'; minProfit = data.minProfit(:)';

    colonySize = 40;  SN = colonySize/2;  maxIter = 1500;  limit = 150;
    RCL_frac = 0.25;

    proto = struct('assign',zeros(I,T), 'open',zeros(1,J), ...
                   'fit',-inf, 'profit',-inf, 'pen',inf, 'trial',0);
    pop = repmat(proto, 1, SN);

    warmStart = try_load_example_assignment(I,T);
    for k = 1:SN
        if ~isempty(warmStart)
            s.assign = warmStart;
            s.open = zeros(1,J);
            for j=1:J, if any(s.assign(:)==j), s.open(j)=1; end, end
            [s.assign, s.open] = repair_contiguity_and_capacity(s.assign, s.open, I,J,T,cap,maxDur,demand,wage,RCL_frac);
        else
            s = randomized_construct(I,J,T,maxDur,cap,demand,wage,RCL_frac);
        end
        [s.fit, s.profit, s.pen] = fitness_strict(s.assign, s.open, ...
            I,J,T,wage,cap,startCost,revenue,minProfit,maxDur,demand);
        s.trial = 0;
        pop(k) = s;
    end

    [bestFit, idx] = max([pop.fit]); best = pop(idx);
    tStart = tic;

    for iter = 1:maxIter
        % Employed
        for k = 1:SN
            v = neighbor_solution_strict(pop, k, I,J,T,cap,maxDur,demand,wage,RCL_frac);
            [v.fit, v.profit, v.pen] = fitness_strict(v.assign, v.open, I,J,T,wage,cap,startCost,revenue,minProfit,maxDur,demand);
            if v.fit > pop(k).fit, pop(k)=v; pop(k).trial=0; else, pop(k).trial=pop(k).trial+1; end
        end
        % Onlooker
        fits = [pop.fit]; prob = (fits - min(fits) + eps) / (sum(fits - min(fits) + eps));
        for kk=1:SN
            k = roulette_wheel(prob);
            v = neighbor_solution_strict(pop, k, I,J,T,cap,maxDur,demand,wage,RCL_frac);
            [v.fit, v.profit, v.pen] = fitness_strict(v.assign, v.open, I,J,T,wage,cap,startCost,revenue,minProfit,maxDur,demand);
            if v.fit > pop(k).fit, pop(k)=v; pop(k).trial=0; else, pop(k).trial=pop(k).trial+1; end
        end
        % Scout
        for k=1:SN
            if pop(k).trial >= limit
                if rand() < 0.5
                    u = randomized_construct(I,J,T,maxDur,cap,demand,wage,RCL_frac);
                else
                    u.assign = zeros(I,T); u.open = zeros(1,J);
                    if ~isempty(warmStart), u.assign = warmStart; for j=1:J, if any(u.assign(:)==j), u.open(j)=1; end, end, end
                    [u.assign, u.open] = repair_contiguity_and_capacity(u.assign, u.open, I,J,T,cap,maxDur,demand,wage,RCL_frac);
                end
                [u.fit, u.profit, u.pen] = fitness_strict(u.assign, u.open, I,J,T,wage,cap,startCost,revenue,minProfit,maxDur,demand);
                u.trial=0; pop(k)=u;
            end
        end

        [iterBestFit, idx] = max([pop.fit]);
        if iterBestFit > bestFit, best = pop(idx); bestFit = iterBestFit; end
        if mod(iter,100)==0, fprintf('Iter %5d | Best Profit: %.2f | Penalty: %.2f\n', iter, best.profit, best.pen); end
    end

    cpuSec = toc(tStart);
    results = build_report(best, I,J,T,cap,revenue,maxDur,demand, cpuSec, maxIter);
%     write_results_excel(results, best.assign, best.open);
end

