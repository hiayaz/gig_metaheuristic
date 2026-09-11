function idx = roulette_wheel(prob)
    r = rand();
    c = cumsum(prob); 
    idx = find(r<=c,1,'first'); 
    if isempty(idx)
        idx=numel(prob); 
    end
end
