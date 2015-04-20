function K = kernel(x1,x2),
% define the kernel you want to use in ordreg here

% polynomial kernel
K = (x1*x2'+1).^2;
return

% RBF kernel
gamma = 1/2;
for i=1:size(x1,1),
  for j = 1:size(x2,1),
    K (i,j) = exp(-sum((x1(i,:)-x2(j,:)).^2)*gamma);
  end
end
