function [fit, profit, pen] = fitness(assign, open, I,J,T,wage,addWage,cap,startCost,revenue,minProfit,maxDur,demand)
    bigM = 1e9; pen = 0;

    for j=1:J
        for t=1:T
            if open(j)==1
                pen = pen + bigM/1000 * abs(sum(assign(:,t)==j) - demand(j,t));
            else
                if sum(assign(:,t)==j)>0, pen = pen + bigM/100; end
            end
        end
    end

    for i=1:I
        for j=1:J
            tt = find(assign(i,:)==j);
            if ~isempty(tt) && ~isequal(tt, min(tt):max(tt))
                pen = pen + bigM/100; % non-contiguous => left then returned
            end
        end
    end

    normalCost=0; overtimeCost=0; startupCostTotal=0;
    for i=1:I
        work = assign(i,:); idx = find(work>0);
        if isempty(idx), continue; end
        blocks = {}; curJ = work(idx(1)); curS = idx(1);
        for k=2:numel(idx)
            if work(idx(k))~=curJ || idx(k)~=idx(k-1)+1
                blocks{end+1} = [curJ, curS, idx(k-1)]; %#ok<AGROW>
                curJ = work(idx(k)); curS = idx(k);
            end
        end
        blocks{end+1} = [curJ, curS, idx(end)]; %#ok<AGROW>

        totalLen = 0; usedProj = [];
        for b=1:numel(blocks)
            j = blocks{b}(1); s = blocks{b}(2); e = blocks{b}(3);
            len = e - s + 1;
            if ~ismember(j, usedProj)
                startupCostTotal = startupCostTotal + startCost(j); % per-project
                usedProj(end+1)=j; %#ok<AGROW>
            end
            normalLeft = max(0, cap(i) - totalLen);
            takeNormal = min(normalLeft, len); takeOver = len - takeNormal;
            normalCost   = normalCost   + wage(i,j) * takeNormal;
            overtimeCost = overtimeCost + (wage(i,j) + addWage(i,j)) * takeOver;
            totalLen = totalLen + len;
        end
    end

    profit = sum(revenue(open==1)) - normalCost - overtimeCost - startupCostTotal;

    if any(minProfit>0)
        costPerJ = zeros(1,J);
        for j=1:J
            usedI = find(any(assign==j,2))';
            for i=usedI
                len = sum(assign(i,:)==j);
                costPerJ(j) = costPerJ(j) + len*(wage(i,j) + 0.5*addWage(i,j));
            end
            costPerJ(j) = costPerJ(j) + startCost(j)*numel(usedI);
            if open(j)==1 && (revenue(j) - costPerJ(j) < minProfit(j)), pen = pen + bigM/10; end
        end
    end

    fit = profit - pen;
end