% -------------------- Feasibility Builder -------------------------------
function [assign, open] = build_feasible(assign, open, I,J,T,cap,maxDur,demand,wage)
    for j=1:J, if open(j)==0, assign(assign==j) = 0; end, end
    for j=1:J
        if maxDur(j) < T
            for t=maxDur(j)+1:T
                assign(assign(:,t)==j,t) = 0;
            end
        end
    end
    for t=1:T
        for j=1:J
            if open(j)==1
                need = demand(j,t); cur = sum(assign(:,t)==j);
                if cur > need
                    ids = find(assign(:,t)==j);
                    [~,ord] = sort(wage(ids,j),'descend');
                    drop = ids(ord(1:(cur-need))); assign(drop,t) = 0;
                elseif cur < need
                    avail = find(assign(:,t)==0);
                    if ~isempty(avail)
                        [~,ord] = sort(wage(avail,j),'ascend');
                        toAdd = avail(ord(1:min(need-cur,numel(avail))));
                        assign(toAdd,t) = j;
                    end
                end
            else
                assign(assign(:,t)==j,t) = 0;
            end
        end
    end
    for j=1:J, if all(assign(:)~=j), open(j)=0; end, end
end