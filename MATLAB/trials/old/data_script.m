clear all, close all
problems  = getproblem('../Scheduling/rawData/frnd_10x10_Train.txt');
%load frnd_8x8_train_data DAT
for IDNUM = 1:100, IDNUM
% problems(IDNUM).p = problems(IDNUM).p(1:8,1:8); problems(IDNUM).sigma = problems(IDNUM).sigma(1:8,1:8);   % force reduction of problem to 8x8
 [DAT(IDNUM).dat, DAT(IDNUM).xTime, DAT(IDNUM).model, DAT(IDNUM).result] = generate_data(problems(IDNUM).p,problems(IDNUM).sigma);
 save frnd_10x10_train_data_new DAT
end
