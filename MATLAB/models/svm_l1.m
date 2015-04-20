function [w,b] = svm_l1(X,y,cw)
G = X*X';
UB = 10000*cw(:);
ell = length(UB);
LB = zeros(ell,1);
H=(y*y').*(X*X');
f=-ones(1,ell);
A=zeros(1,ell);
c=0;
Aeq=y';
ceq=0;
alpha=quadprog(H,f,A,c,Aeq,ceq,LB,UB);
w=X'*(alpha.*y);
i=min(find((alpha>0.001)&(y==1)));
b=1-G(i,:)*(alpha.*y);
