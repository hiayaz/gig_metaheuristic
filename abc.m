%50 freelancer
% abc_gig_scheduling.m (FIXED)
% - Fixed: proper struct preallocation for 'pop' to avoid
%   "Subscripted assignment between dissimilar structures."
% - Fixed: removed stray '>' typo in an 'end' statement.
%
% Usage:
%   results = abc_gig_scheduling();

clc
clear all
iterasyon=[];

for SubProb=1:9
    SP=[10 20 30 40 50 100 250 500 1000];
    data = build_demo_data(SP(1,SubProb));
    for sira=1:30
        sprintf('SubProblem Size_%d_Replication_%d',SP(SubProb),sira)
        % SP(SubProb),sira
        rng(42);  % reproducibility
    
        % % Try to load input.xlsx; otherwise build demo dataset (Experiment 1.1-like)
        % if isfile('input.xlsx')
        %     data = load_input_excel('input.xlsx');
        % else
        %     warning('input.xlsx not found. Building demo dataset for 10 freelancers, 6 projects, 12 periods.');
        %     data = build_demo_data(10);
        % end
    
        I = data.I; J = data.J; T = data.T;
        wage = data.wage;               % I x J normal wage per period
        addWage = data.addWage;         % I x J overtime premium per period
        cap = data.cap(:)';             % 1 x I capacity (normal periods) of freelancer i
        demand = data.demand;           % J x T demand (workers) for project j in period t
        revenue = data.revenue(:)';     % 1 x J project revenue if opened
        maxDur = data.maxDur(:)';       % 1 x J maximum project duration
        startCost = data.startCost(:);     % 1 x J startup cost per freelancer-project pair
        minProfit = data.minProfit(:)'; % 1 x J minimum acceptable profit threshold (may be zeros)
    
        % ABC parameters
        colonySize = 40;             % total bees
        SN = colonySize/2;           % number of food sources
        maxIter = 5000;
        limit = 150;                 % abandonment limit
    
        % Preallocate consistent struct to avoid "dissimilar structures"
        proto = struct('assign',zeros(I,T), 'open',zeros(1,J), ...
                       'fit',-inf, 'profit',-inf, 'pen',inf, 'trial',0);
        pop = repmat(proto, 1, SN);
    
        for k = 1:SN
            s = random_solution(I,J,T,maxDur);
            [s.assign, s.open] = build_feasible(s.assign, s.open, I,J,T,cap,maxDur,demand,wage);
            [s.fit, s.profit, s.pen] = fitness(s.assign, s.open, I,J,T,wage,addWage,cap,startCost,revenue,minProfit,maxDur,demand);
            s.trial = 0;
            pop(k) = s;
        end
    
        [bestFit, idx] = max([pop.fit]); best = pop(idx);
        tStart = tic;
    
        for iter = 1:maxIter
            % Employed
            for k = 1:SN
                v = neighbor_solution(pop, k, I,J,T,cap);
                [v.assign, v.open] = build_feasible(v.assign, v.open, I,J,T,cap,maxDur,demand,wage);
                [v.fit, v.profit, v.pen] = fitness(v.assign, v.open, I,J,T,wage,addWage,cap,startCost,revenue,minProfit,maxDur,demand);
                if v.fit > pop(k).fit, pop(k) = v; pop(k).trial = 0; else, pop(k).trial = pop(k).trial + 1; end
            end
            % Onlooker
            fits = [pop.fit]; prob = (fits - min(fits) + eps) / (sum(fits - min(fits) + eps));
            for kk = 1:SN
                k = roulette_wheel(prob);
                v = neighbor_solution(pop, k, I,J,T,cap);
                [v.assign, v.open] = build_feasible(v.assign, v.open, I,J,T,cap,maxDur,demand,wage);
                [v.fit, v.profit, v.pen] = fitness(v.assign, v.open, I,J,T,wage,addWage,cap,startCost,revenue,minProfit,maxDur,demand);
                if v.fit > pop(k).fit, pop(k) = v; pop(k).trial = 0; else, pop(k).trial = pop(k).trial + 1; end
            end
            % Scout
            for k = 1:SN
                if pop(k).trial >= limit
                    u = random_solution(I,J,T,maxDur);
                    [u.assign, u.open] = build_feasible(u.assign, u.open, I,J,T,cap,maxDur,demand,wage);
                    [u.fit, u.profit, u.pen] = fitness(u.assign, u.open, I,J,T,wage,addWage,cap,startCost,revenue,minProfit,maxDur,demand);
                    u.trial = 0;  % ensure field parity
                    pop(k) = u;
                end
            end
    
            [iterBestFit, idx] = max([pop.fit]);
            if iterBestFit > bestFit, best = pop(idx); bestFit = iterBestFit; end
%             if mod(iter,100)==0, fprintf('Iter %5d | Best Profit: %.2f | Penalty: %.2f\n', iter, best.profit, best.pen); end
            iterasyon(iter,sira)=best.profit;
        end
    
        cpuSec = toc(tStart);
        results = build_report(best, I,J,T,cap,revenue,maxDur,demand, cpuSec, maxIter);
    %     write_results_excel(results, best.assign, best.open);
    
%     totalbest{sira}=best;
%     BestProfit(sira,1)=best.profit;
%     save('BestProfit.mat','BestProfit')
%     save('totalbest.mat','totalbest')
    
    end
    p_inf=sprintf('SubProblem Size_%d_Iterasyon5000.mat',SP(SubProb));
    save(p_inf,'iterasyon');
    clc
    clear all
end



