% Direct classification approach
clear all, close all

load alldata data_opt data_sub

Xdir = [data_opt;data_sub];
Ydir = [ones(length(data_opt),1);zeros(length(data_sub),1)];
rbfmodel = svmtrain(Ydir,Xdir,'-s 0 -h 0')

for t = 1:length(DAT)
  dat = DAT(t).dat;
  optimal = min(dat(:,2));
  for i = 1:n*m
    data = dat((i==dat(:,1)),:);
    v = data(:,3:end)*model.w'-model.bias;
    % v = svmpredict(ones(size(data,1),1),data(:,3:end),svmodel);
    if isempty(v)
      Classify(t,i) = 1;
      rho(t,i) = 0;
    else
      [~,idx] = max(v);
      rho(t,i) = (data(idx,2)-optimal)/optimal;
      if (data(idx,2) == optimal)
        Classify(t,i) = 1;
      else
        Classify(t,i) = 0;
        [~,J]=sort(v);
%        data(J,2)'
      end
    end
  end
end

