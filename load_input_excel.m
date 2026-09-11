function data = load_input_excel(filename)
    % Projects: [revenue, maxDur, minProfit, startCost] in columns B..E
    P = readmatrix(filename,'Sheet','Projects','Range','B2:F1000');
    J = size(P,1);
    revenue   = P(:,1)'; 
    maxDur    = P(:,2)'; 
    minProfit = P(:,3)';
    if size(P,2) >= 4 && any(~isnan(P(:,4)))
        startCost = P(:,4)';  % per-project
    else
        G = readmatrix(filename,'Sheet','Global');
        if isempty(G)
            error('Global sheet is empty and Projects does not include startCost.');
        end
        G = G(:)';
        if numel(G)==1
            startCost = G(1) * ones(1,J);
        elseif numel(G)==J
            startCost = G;
        else
            error('Global!startCost must be scalar or length J. Found length %d while J=%d.', numel(G), J);
        end
    end

    % Freelancers
    F = readmatrix(filename,'Sheet','Freelancers','Range','B2:B1000');
    cap = F(:)'; I = numel(cap);

    % Wage / AddWage
    W = readmatrix(filename,'Sheet','Wage');
    if size(W,1) ~= I || size(W,2) ~= J, error('Wage sheet must be I x J.'); end
    wage = W;

    try
        AW = readmatrix(filename,'Sheet','AddWage');
        if size(AW,1)==I && size(AW,2)==J, addWage = AW; else, addWage = 0.3*wage; end
    catch
        addWage = 0.3*wage;
    end

    % Demand (J x T)
    D = readmatrix(filename,'Sheet','Demand');
    if size(D,1) ~= J, error('Demand sheet must have J rows.'); end
    demand = D; T = size(demand,2);

    data = struct('I',I,'J',J,'T',T,'wage',wage,'addWage',addWage,'cap',cap, ...
                  'demand',demand,'revenue',revenue,'maxDur',maxDur, ...
                  'startCost',startCost,'minProfit',minProfit);
end