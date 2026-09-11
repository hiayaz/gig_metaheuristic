clc
clear all
load('SubProblem Size_1000_Iterasyon5000.mat')
for i=1:30
    for j=1:4999
        fark(j,i)=iterasyon(j+1,i)-iterasyon(j,i);
    end
end

