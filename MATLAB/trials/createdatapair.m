function [x1, x2, y12, pair] = createdatapair(X, y, cut),
%CREATEDATAPAIR create data pair for ordinal regression (ranking problem)
% usage: [X1, X2, y12, pair] = createdatapair(X, y),

% create new data set:
ell = length(y);
if (nargin < 3), cut = ell; end
m = 0; 

% ties broken in first come first served but should be batched in one rank
[dummy, I] = sort(y);
%rand(1,100); I = randperm(ell);

if (ell == 2), % special case
  m = m + 1; x1(:,m) = X(:,I(1)); x2(:,m) = X(:,I(ell));
  y12(m) = sign (y(I(1)) - y(I(ell)));
  pair(1:2,m) = [I(1);I(ell)];
  m = m + 1; x1(:,m) = X(:,I(ell)); x2(:,m) = X(:,I(1));
  y12(m) = sign (y(I(ell)) - y(I(1)));
  pair(1:2,m) = [I(ell);I(1)];
else
  if (0 ~= sign (y(I(1)) - y(I(2)))) 
    m = m + 1; x1(:,m) = X(:,I(1)); x2(:,m) = X(:,I(2));
    y12(m) = sign (y(I(1)) - y(I(2)));
    pair(1:2,m) = [I(1);I(2)];
  end
  for i = 2:cut-1,
    if (0 ~= sign (y(I(i)) - y(I(i-1)))) 
      m = m + 1; x1(:,m) = X(:,I(i)); x2(:,m) = X(:,I(i-1));
      y12(m) = sign (y(I(i)) - y(I(i-1)));
      pair(1:2,m) = [I(i);I(i-1)];
    end
    if (0 ~= sign (y(I(i)) - y(I(i+1)))) 
      m = m + 1; x1(:,m) = X(:,I(i)); x2(:,m) = X(:,I(i+1));
      y12(m) = sign (y(I(i)) - y(I(i+1)));
      pair(1:2,m) = [I(i);I(i+1)];
    end
  end
  m = m + 1; x1(:,m) = X(:,I(cut)); x2(:,m) = X(:,I(cut-1));
  y12(m) = sign (y(I(cut)) - y(I(cut-1)));
  pair(1:2,m) = [I(cut);I(cut-1)];

  for i = cut+1:ell, % chopping method from the last solutions
    if (0 ~= sign (y(I(i)) - y(I(cut)))) 
      m = m + 1; x1(:,m) = X(:,I(i)); x2(:,m) = X(:,I(cut));
      y12(m) = sign (y(I(i)) - y(I(cut)));
      pair(1:2,m) = [I(i);I(cut)];
    end
    if (0 ~= sign (y(I(cut)) - y(I(i)))) 
      m = m + 1; x1(:,m) = X(:,I(cut)); x2(:,m) = X(:,I(i));
      y12(m) = sign (y(I(cut)) - y(I(i)));
      pair(1:2,m) = [I(cut);I(i)];
    end
  end
end