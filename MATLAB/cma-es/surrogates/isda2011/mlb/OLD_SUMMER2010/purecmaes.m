function [xmin,stats,FCNEVAL]=purecmaes(strfitnessfct, N, param),
% CMA-ES: Evolution Strategy with Covariance Matrix Adaptation for
  % nonlinear function minimization. To be used under the terms of the
  % GNU General Public License (http://www.gnu.org/copyleft/gpl.html).
  %
  % This code is an excerpt from cmaes.m and implements the key parts
  % of the algorithm. It is intendend to be used for READING and
  % UNDERSTANDING the basic flow and all details of the CMA
  % *algorithm*. Use the cmaes.m code to run serious simulations. It
  % is somewhat longer but it is supposed to be saver, faster and,
  % after all, more practicable.
  %
  % Author: Nikolaus Hansen, 2003. 
  % e-mail: hansen[at]bionik.tu-berlin.de
  % URL: http://www.bionik.tu-berlin.de/user/niko
  % References: See end of file. Last change: October, 27, 2004

global  mu  

% --------------------  Initialization --------------------------------  

% User defined input parameters (need to be edited)
  xmean = rand(N,1); %[-1.9 1]';       % objective variables initial point
  sigma = 0.5;             % coordinate wise standard deviation (step size)
  stopfitness = 1e-10;  % stop if fitness < stopfitness (minimization)
  stopeval = 1e3*N;     % stop after stopeval number of function evaluations
  
  % Strategy parameter setting: Selection  
  lambda = 4+floor(3*log(N));  % population size, offspring number
  mu = floor(lambda/4);        % number of parents/points for recombination
  % weights = log(mu+1)-log(1:mu)'; % muXone array for weighted recombination
  % lambda=12; mu=3; weights = ones(mu,1); % uncomment for (3_I,12)-ES
  weights = ones(mu,1);
  mueff=sum(weights)^2/sum(weights.^2); % variance-effective size of mu

  % Strategy parameter setting: Adaptation
  cc = 4/(N+4);    % time constant for cumulation for covariance matrix
  cs = (mueff+2)/(N+mueff+3); % t-const for cumulation for sigma control
  mucov = mueff;   % size of mu used for calculating learning rate ccov
  ccov = (1/mucov) * 2/(N+1.4)^2 + (1-1/mucov) * ...  % learning rate for
         ((2*mueff-1)/((N+2)^2+2*mueff));             % covariance matrix
  damps = 1 + 2*max(0, sqrt((mueff-1)/(N+1))-1) + cs; % damping for sigma 
                                                      % usually close to 1
                                                    % former damp == damps/cs
  
  % Initialize dynamic (internal) strategy parameters and constants
  pc = zeros(N,1); ps = zeros(N,1);   % evolution paths for C and sigma
  B = eye(N);                         % B defines the coordinate system
  D = eye(N);                         % diagonal matrix D defines the scaling
  C = B*D*(B*D)';                     % covariance matrix
  chiN=N^0.5*(1-1/(4*N)+1/(21*N^2));  % expectation of 
                                      %   ||N(0,I)|| == norm(randn(N,1))
  weights = weights/sum(weights);     % normalize recombination weights array
  
  ell = 2;                            % training data initilized
  stats = [];
  
  for k = 1:ell, 
    ary(:,k) = xmean + randn(N,1);
    arfy(k) = feval(strfitnessfct, ary(:,k)); 
  end 
  maxell = 1*lambda;

  % -------------------- Generation Loop --------------------------------

  counteval = ell;  % the next 40 lines contain the 20 lines of interesting code 
  telja = 0;
  while counteval < stopeval
     telja = telja + 1;
    
    % Generate and evaluate lambda offspring
    arz = randn(N,lambda);  % array of normally distributed mutation vectors
    for k=1:lambda,
      arx(:,k) = xmean + sigma * (B*D * arz(:,k));   % add mutation  % Eq. (1)
    end
    
    if rem(telja,param.updateFactor)
      repeat=0; % Only perform prediction
    else
      repeat=lambda; % Update model, and perform prediction      
    end
    
    % perform Ordinal regression
    if param.useXmean
      [arfitness, ary, arfy, funceval] = ordinalregression([xmean arx], ary, arfy, strfitnessfct, repeat, param);
      arfitness = arfitness(2:end); % get rid off the pseudo point xmean
    else
      [arfitness, ary, arfy, funceval] = ordinalregression(arx, ary, arfy, strfitnessfct, repeat, param);
    end
      
    FCNEVAL(telja) = funceval;
    counteval = counteval + funceval;
  
    if strcmpi(param.delete,'old')
      % delete very old data points from data set
      while (length(arfy) > maxell), ary(:,1) = []; arfy(1) = []; end  
    elseif strcmpi(param.delete,'bad')
      % delete bad data points from data set (training data is sorted in ascending order)
      [arfy, idy] = sort(arfy,'ascend'); ary=ary(:,idy);
      while (length(arfy) > maxell), ary(:,end) = []; arfy(end) = []; end
    end
      
    % Sort by fitness and compute weighted mean into xmean
    [arfitness, arindex] = sort(arfitness); % minimization
    xmean = arx(:,arindex(1:mu))*weights;   % recombination, new mean value
    zmean = arz(:,arindex(1:mu))*weights;   % == sigma^-1*D^-1*B'*(xmean-xold)
    
    % Cumulation: Update evolution paths
    ps = (1-cs)*ps + sqrt(cs*(2-cs)*mueff) * (B * zmean);            % Eq. (4)
    hsig = norm(ps)/sqrt(1-(1-cs)^(2*counteval/lambda))/chiN < 1.5 + 1/(N+1);
    pc = (1-cc)*pc ...
          + hsig * sqrt(cc*(2-cc)*mueff) * (B * D * zmean);          % Eq. (2)

    % Adapt covariance matrix C
    C = (1-ccov) * C ...                    % regard old matrix      % Eq. (3)
         + ccov * (1/mucov) * (pc*pc' ...   % plus rank one update
                               + (1-hsig) * cc*(2-cc) * C) ...
         + ccov * (1-1/mucov) ...           % plus rank mu update 
           * (B*D*arz(:,arindex(1:mu))) ...
           *  diag(weights) * (B*D*arz(:,arindex(1:mu)))';               

    % Adapt step size sigma
    sigma = sigma * exp((cs/damps)*(norm(ps)/chiN - 1));             % Eq. (5)
    
    % Update B and D from C
    % This is O(N^3). When strategy internal CPU-time is critical, the
    % next three lines can be executed only every (alpha/ccov/N)-th
    % iteration step, where alpha is e.g. between 0.1 and 10 
    C=triu(C)+triu(C,1)'; % enforce symmetry
    [B,D] = eig(C);       % eigen decomposition, B==normalized eigenvectors
    D = diag(sqrt(diag(D))); % D contains standard deviations now

    % Break, if fitness is good enough
    if min(arfy) <= stopfitness 
      break;
    end

    %disp([num2str(counteval) ': ' num2str(min(arfy))]);

    stats = [stats; counteval min(arfy)];
    
  end % while, end generation loop

  % -------------------- Ending Message ---------------------------------

  disp([num2str(counteval) ': ' num2str(feval(strfitnessfct, arx(:,arindex(1))))]);
  xmin = arx(:, arindex(1)); % Return best point of last generation.
                             % Notice that xmean is expected to be even
                             % better.
  
% ---------------------------------------------------------------  

function f=fschwefel(x)
  f = 0;
  for i = 1:size(x,1),
    f = f+sum(x(1:i))^2;
  end

function f=fcigar(x)
  f = x(1)^2 + 1e6*sum(x(2:end).^2);
  
function f=fcigtab(x)
  f = x(1)^2 + 1e8*x(end)^2 + 1e4*sum(x(2:(end-1)).^2);
  
function f=ftablet(x)
  f = 1e6*x(1)^2 + sum(x(2:end).^2);
  
function f=felli(x)
  N = size(x,1); if N < 2 error('dimension must be greater one'); end
  f=1e6.^((0:N-1)/(N-1)) * x.^2;

function f=felli100(x)
  N = size(x,1); if N < 2 error('dimension must be greater one'); end
  f=1e4.^((0:N-1)/(N-1)) * x.^2;

function f=fplane(x)
  f=x(1);

function f=ftwoaxes(x)
  f = sum(x(1:floor(end/2)).^2) + 1e6*sum(x(floor(1+end/2):end).^2);

function f=fparabR(x)
  f = -x(1) + 100*sum(x(2:end).^2);

function f=fsharpR(x)
  f = -x(1) + 100*norm(x(2:end));
  
function f=fdiffpow(x)
  N = size(x,1); if N < 2 error('dimension must be greater one'); end
  f=sum(abs(x).^(2+10*(0:N-1)'/(N-1)));
  
function f=frastrigin10(x)
  N = size(x,1); if N < 2 error('dimension must be greater one'); end
  scale=10.^((0:N-1)'/(N-1));
  f = 10*size(x,1) + sum((scale.*x).^2 - 10*cos(2*pi*(scale.*x)));

function f=frand(x)
  f=rand;

function f=fgriewank(x)
  N = size(x,1); if N < 2 error('dimension must be greater one'); end 
  fr = 4000;
  s = 0;
  p = 1;
  for j = 1:N; s = s+x(j)^2; end
  for j = 1:N; p = p*cos(x(j)/sqrt(j)); end
  y = s/fr-p+1;
  
% ---------------------------------------------------------------  
%%% REFERENCES
%
% The equation numbers refer to 
% Hansen, N. and S. Kern (2004). Evaluating the CMA Evolution
% Strategy on Multimodal Test Functions.  Eighth International
% Conference on Parallel Problem Solving from Nature PPSN VIII,
% Proceedings, pp. 282-291, Berlin: Springer. 
% (http://www.bionik.tu-berlin.de/user/niko/ppsn2004hansenkern.pdf)
% 
% Further references:
% Hansen, N. and A. Ostermeier (2001). Completely Derandomized
% Self-Adaptation in Evolution Strategies. Evolutionary Computation,
% 9(2), pp. 159-195.
% (http://www.bionik.tu-berlin.de/user/niko/cmaartic.pdf).
%
% Hansen, N., S.D. Mueller and P. Koumoutsakos (2003). Reducing the
% Time Complexity of the Derandomized Evolution Strategy with
% Covariance Matrix Adaptation (CMA-ES). Evolutionary Computation,
% 11(1).  (http://mitpress.mit.edu/journals/pdf/evco_11_1_1_0.pdf).
%

