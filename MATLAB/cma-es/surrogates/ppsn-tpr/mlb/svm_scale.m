function [scalefac, offset] = svm_scale(Z, scalefac, offset),
%SVM_SCALE SVM scaling 
% usage [scalefac, offset] = svm_scale(Z),
% scaledZ = scalefac*ones(1,ell).*(Z - offset*ones(1,ell)) - 1 for a [-1 1] range
% scaledZ = scalefac*ones(1,ell).*(Z - offset*ones(1,ell)) - 1 for a [-1 1]

if (nargin == 3)
  ell = size(Z,2);
  scalefac = scalefac*ones(1,ell).*(Z - offset*ones(1,ell)) - 1;
else

%scalefac = ones(size(Z,1),1)./sqrt(max(sum(Z.^2,1))); offset = -1./scalefac;
%scalefac = 1; offset = -1./scalefac;

Zmax = max(Z,[],2); offset = min(Z,[],2);

%Zmax = ones(size(Z,1),1)*max(Z(:)); offset = ones(size(Z,1),1)*min(Z(:));

scalefac = 2 ./ (Zmax - offset);
end