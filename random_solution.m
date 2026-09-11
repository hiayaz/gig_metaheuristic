function s = random_solution(I,J,T,maxDur)
    % Çeşitlilik için: global RNG'yi bozmadan yerel akış
    rs = RandStream('mt19937ar','Seed','shuffle');

    % 1) Açık proje setini rastgele seç (en az ~J/3 proje)
    minOpen = max(1, ceil(J/3));
    Kopen   = randi(rs, J - minOpen + 1) + (minOpen - 1);    % [minOpen .. J]
    permJ   = randperm(rs, J);
    open    = zeros(1,J);
    open(permJ(1:Kopen)) = 1;

    % 2) Başlangıç atama matrisi (I x T), aynı dönemde bir freelancer en fazla 1 projede
    assign = zeros(I,T);

    for t = 1:T
        % Bu dönemde açık ve süresi uygun projeler
        validJ = find(open==1 & t <= maxDur);
        if isempty(validJ), continue; end

        % Proje ve freelancer sırasını her dönem karıştır
        validJ = validJ(randperm(rs, numel(validJ)));
        freeList = randperm(rs, I);   % o dönemde boş freelancer kuyruğu

        % Her proje için rastgele sayıda kişi ata (0..taban)
        % Tabanı, açık proje sayısına bağlı şekilde ayarla:
        basePerProj = max(1, ceil(I/(2*max(1,numel(validJ)))));  % kaba üst sınır

        for jj = 1:numel(validJ)
            if isempty(freeList), break; end
            j = validJ(jj);

            % Bu (j,t) için kaç kişi? 0..basePerProj arası rastgele
            k = randi(rs, basePerProj + 1) - 1;                  % 0..basePerProj
            k = min(k, numel(freeList));
            if k > 0
                pick = freeList(1:k);
                assign(pick, t) = j;
                freeList(1:k) = [];
            end
        end
    end

    % 3) Emniyet: maxDur sonrası atamaları temizle (yukarıda zaten engelleniyor)
    for j = 1:J
        if maxDur(j) < T
            assign(assign(:, maxDur(j)+1:T) == j, maxDur(j)+1:T) = 0;
        end
    end

    s.assign = assign;
    s.open   = open;
end