function v = neighbor_solution(pop, k, I, J, T, cap)
% Komşu üretici:
% - case 1: proje aç/kapat (aynı)
% - case 2: TAM SATIR SWAP — toplam çalışma uzunlukları eşit iki freelancerı bul,
%            tüm dönemlerdeki atamalarını birbirleriyle değiştir.
%            (Eşit yoksa en yakınıyla swap yapar.)
% - case 3: UZATMA AZALT — kapasite veren çağrılarda (cap) uzatması olan bir
%            freelancerın tek bir KESİNTİSİZ BLOK’unu, aynı aralıkta boş ve
%            kapasitesi yeten başka bir freelancera komple taşı.

    if nargin < 6
        cap = []; % kapasite verilmediyse, case 3 daha yumuşak davranır
    end

    v = pop(k);
    move = randi(3);

    switch move
        case 1  % --- Proje aç/kapat (flip)
            j = randi(J);
            v.open(j) = 1 - v.open(j);
            if v.open(j) == 0
                v.assign(v.assign == j) = 0; % kapatılan projedeki tüm atamaları temizle
            end

        case 2  % --- TAM SATIR SWAP (eşit uzunluk tercihli)
            used = sum(v.assign > 0, 2);      % i'nin toplam çalışma uzunluğu
            i1 = randi(I);
            sameLen = find(used == used(i1));
            sameLen(sameLen == i1) = [];      % kendisini çıkar

            if ~isempty(sameLen)
                i2 = sameLen(randi(numel(sameLen)));
            else
                % eşit uzunluk yoksa en yakın uzunluktakiyle swap
                [~, ord] = sort(abs(used - used(i1)));
                i2 = ord(find(ord ~= i1, 1, 'first'));
            end

            tmp = v.assign(i1, :);
            v.assign(i1, :) = v.assign(i2, :);
            v.assign(i2, :) = tmp;

            % Not: satır swap yapmak, (j,t) bazında kişi sayısını değiştirmez;
            % talep sayıları korunur. Sadece "kimin" çalıştığı değişir.

        case 3  % --- UZATMA AZALT (blok transfer)
            used = sum(v.assign > 0, 2);

            if ~isempty(cap)
                over = find(used(:) > cap(:)); % uzatması olanlar
            else
                over = []; % kapasite yoksa "yoğun" birini seç
            end

            if isempty(over)
                % kapasite verilmemişse veya uzatma yoksa: yoğun birini seç
                [~, ord] = sort(used, 'descend');
                i_over = ord(1);
            else
                i_over = over(randi(numel(over)));
            end

            % i_over için rastgele bir dolu dönem seç, onun çevresindeki BLOK'u büyüt
            occ = find(v.assign(i_over, :) > 0);
            if ~isempty(occ)
                t0 = occ(randi(numel(occ)));
                j0 = v.assign(i_over, t0);

                % BLOK'u [s:e] bul (kesintisiz aynı proje)
                s = t0; e = t0;
                while s > 1   && v.assign(i_over, s-1) == j0, s = s - 1; end
                while e < T   && v.assign(i_over, e+1) == j0, e = e + 1; end
                L = e - s + 1;

                % ALICI adayları: [s:e] aralığı komple boş olan ve kapasitesi yetenler
                cand = setdiff(1:I, i_over);
                isFree = false(numel(cand), 1);
                roomOK = true(numel(cand), 1);

                for idx = 1:numel(cand)
                    ii = cand(idx);
                    isFree(idx) = all(v.assign(ii, s:e) == 0);
                    if ~isempty(cap)
                        roomOK(idx) = (used(ii) + L) <= cap(ii);
                    end
                end

                okIdx = find(isFree & roomOK);
                if ~isempty(okIdx)
                    i_recv = cand(okIdx(randi(numel(okIdx))));
                    % BLOK'u taşı: i_over → i_recv
                    v.assign(i_recv, s:e) = j0;
                    v.assign(i_over, s:e) = 0;
                else
                    % Tam blok taşınamıyorsa, daha kısa bir alt-blok dene (greedy kısaltma)
                    moved = false;
                    for L2 = L-1 : -1 : 1
                        % sol ve sağtan L2 uzunluklu alt bloklar denensin
                        candBlocks = [s, s+L2-1;  e-L2+1, e];
                        for bb = 1:size(candBlocks,1)
                            s2 = candBlocks(bb,1); e2 = candBlocks(bb,2);
                            cand2 = setdiff(1:I, i_over);
                            ok2 = false(numel(cand2),1);
                            for idx = 1:numel(cand2)
                                ii = cand2(idx);
                                if all(v.assign(ii, s2:e2) == 0)
                                    if isempty(cap) || (used(ii) + (e2-s2+1) <= cap(ii))
                                        ok2(idx) = true;
                                    end
                                end
                            end
                            idxOK = find(ok2);
                            if ~isempty(idxOK)
                                i_recv = cand2(idxOK(randi(numel(idxOK))));
                                v.assign(i_recv, s2:e2) = j0;
                                v.assign(i_over, s2:e2) = 0;
                                moved = true;
                                break;
                            end
                        end
                        if moved, break; end
                    end
                    % Hiç hareket olmazsa, komşu aynı kalır (ABC zaten başka hamle dener)
                end
            end
    end
end
