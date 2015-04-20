function [Jbn,Abn] = criticalpath(xTime,p)
% CRITICALPATH

CT = xTime'+p;
[J,A] = find(CT==max(CT(:))); 
J=J(1);A=A(1);
time = xTime(A,J);
Abn = A; Jbn = J; 
while (time > 0)
  [J,A] = find(CT == time);
  if length(A)>1
     if any(Jbn(end)==J)
       A = A(J==Jbn(end));
       J = J(J==Jbn(end));
     elseif any(Abn(end)==A)
       J = J(A==Abn(end));
       A = A(A==Abn(end));
     end
  end
  time = xTime(A,J);
  Abn = [Abn A];
  Jbn = [Jbn J];
end
