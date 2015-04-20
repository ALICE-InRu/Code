function [meanEval,medianEval,stdEval]=hei2plot(T,N,m,M,color)
%%% plot
figure(1), subplot(M,2,ceil(m/2)), hold on,
if T==1, 
  if strcmpi(color,'dark'), litur=[1 0 0]; 
  elseif strcmpi(color,'light'), litur=[1 0.8 0.8]; end
elseif T==6, 
  if strcmpi(color,'dark'), litur=[0 0 1]; 
  elseif strcmpi(color,'light'), litur=[0.8 0.8 1]; end
end
%uLen=sort(unique(len),'descend'); U=length(uLen);
%for i=1:U, wuLen(i)=length(find(len==uLen(i))); end
%tmp=0; for i=1:U
%  tmp=tmp+wuLen(i); tmp2=1-tmp/100;
%  if T==1, lineType='-'; litur=[1 tmp2 tmp2];
%  elseif T==6, lineType='-'; litur=[tmp2 tmp2 1]; 
%  end
%  if (tmp2>=0) && (tmp2<=1), plot(1:uLen(i),meanfunc(1:uLen(i)),lineType,'Color',litur), end
%end

if strcmpi(color,'dark'),
  maxM=ceil(max(meanfunc))+2; minM=0;%floor(min(meanfunc))-1;
  meanG=median(gen); plot([meanG meanG],[minM maxM],'--', 'Color', litur)
  y=meanfunc; x=1:length(y); b=polyfit(x,y,5); yhat=polyval(b,x); 
  %n=zeros(1,length(funEv)); for i=1:K, for j=1:length(n), if ~isnan(funEv(i,j)), n(j)=n(j)+1; end, end, end
  plot(yhat,'Color',litur,'LineWidth',2)
  if ((m==M*4) || (m==(M*4-2))), xlabel('# generations'); end 
  if mod(m,4)==1, ylabel('Mean func. eval.'); end
  title(['$n=' num2str(N) ,'$'],'interpreter','latex','FontSize',13)
elseif strcmpi(color,'light')
  plot(1:uLen(1),meanfunc(1:uLen(1)),'-','Color',litur)  
end

end