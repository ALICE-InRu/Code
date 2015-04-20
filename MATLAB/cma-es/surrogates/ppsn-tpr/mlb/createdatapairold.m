function [x1, x2, y12, pair] = createdatapair(X, y, method),
%CREATEDATAPAIR create data pair for ordinal regression (ranking problem)

if (nargin < 3), method = 3; end % default method

% create new data set:
m = 0; ell = length(y)

if (1 == method)
  [dummy, I] = sort(y); % BREAK TIES!!!
  m = m + 1; x1(m,:) = X(I(1),:); x2(m,:) = X(I(2),:);
  y12(m,1) = sign (y(I(1)) - y(I(2)));
  pair(m,1:2) = [I(1) I(2)];
  for i = 2:ell-1,
    m = m + 1; x1(m,:) = X(I(i),:); x2(m,:) = X(I(i-1),:);
    y12(m,1) = sign (y(I(i)) - y(I(i-1)));
    pair(m,1:2) = [I(i) I(i-1)];
    m = m + 1; x1(m,:) = X(I(i),:); x2(m,:) = X(I(i+1),:);
    y12(m,1) = sign (y(I(i)) - y(I(i+1)));
    pair(m,1:2) = [I(i) I(i+1)];
  end
  m = m + 1; x1(m,:) = X(I(ell),:); x2(m,:) = X(I(ell-1),:);
  y12(m,1) = sign (y(I(ell)) - y(I(ell-1)));
  pair(m,1:2) = [I(ell) I(ell-1)];m
elseif (2 == method)
  for i = 1:ell,
    for j = (i+1):ell,
      % now generate the data vector:
      m = m + 1;
      x1(m,:) = X(i,:); x2(m,:) = X(j,:);
      y12(m,1) = sign (y(i) - y(j));
      pair(m,1:2) = [i j];
    end
  end
elseif (3 == method)
  for rnk = 1:ell,
    classes = 1:max(y); classes(rnk) = [];
    for k = classes,
      % generate a random sample of type rnk
      i = rnk;
      I = find(y == k);
      j = I(ceil(rand(1)*length(I)));
      % now generate the data vector:
      m = m + 1;
      x1(m,:) = X(i,:); x2(m,:) = X(j,:);
      y12(m,1) = sign (y(i) - y(j));
      pair(m,1:2) = [i j];
    end
  end
end