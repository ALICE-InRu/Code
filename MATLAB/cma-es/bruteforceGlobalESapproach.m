%   BRUTEFORCE SEARCH USING CMA-ES TO FIND OPTIMAL WEIGHTS FOR LINEAR
%   ORD.REG.MODEL - outer function
%   [xmin,weights] = bruteforceESapproach 
%  
%   input:  ---> Following param need to be edited prior to run
%         * param numFeatures, number of features (same as in: getFeatures.m)
%         * param datadistr, type of datadistribution, 
%                 e.g. rawData/Uniform10x100_n6xm5/train.mat
%  
%   output: var xmin, minimum mean makespan of problem instances 
%           var weights, linear weights, run bruteforceESapproach.m for
%                 SLLPDR form
%         --> results are saved on-the-fly in jsspES.mat
%   
%   dependant files: SLLPDR.m (and thus also getFeatures.m jsp_ch.m)
function [xmin esWeights]=bruteforceGlobalESapproach(problem)
global numFeatures numJobs numMacs rawData
numFeatures=13;
numJobs=6;
numMacs=5;
dim=sprintf('%dx%d',numJobs,numMacs);
addpath ..\common\
%% get data 
rawData=getproblem(sprintf('../../rawData/%s.%s.train.txt',problem,dim),500,sprintf('../opt/opt.%s.%s.train.mat',problem,dim));

% --------------------  Initialization --------------------------------
%% User defined input parameters (need to be edited)
savename=sprintf('%s.%d-cmarun.mat',problem,dim);
  
  %% CMA-ES search commences:
  strfitnessfct = 'applyglobalweights';  % name of objective/fitness function
  N = (numFeatures+1);   % number of objective variables/problem dimension
  xmean = rand(N,1);    % objective variables initial point
  %%
  sigma = 0.5;          % coordinate wise standard deviation (step size)
  stopfitness = 1e-10;  % stop if fitness < stopfitness (minimization)
  stopeval = 50000; %1e3*N^2;   % stop after stopeval number of function evaluations
  
  %% Strategy parameter setting: Selection  
  lambda = 4+floor(3*log(N));  % population size, offspring number
  mu = lambda/2;               % number of parents/points for recombination
  weights = log(mu+1/2)-log(1:mu)'; % muXone array for weighted recombination
  mu = floor(mu);        
  weights = weights/sum(weights);       % normalize recombination weights array
  mueff=sum(weights)^2/sum(weights.^2); % variance-effectiveness of sum w_i x_i

  %% Strategy parameter setting: Adaptation
  cc = (4 + mueff/N) / (N+4 + 2*mueff/N); % time constant for cumulation for C
  cs = (mueff+2) / (N+mueff+5);  % t-const for cumulation for sigma control
  c1 = 2 / ((N+1.3)^2+mueff);    % learning rate for rank-one update of C
  cmu = min(1-c1, 2 * (mueff-2+1/mueff) / ((N+2)^2+mueff));  % and for rank-mu update
  damps = 1 + 2*max(0, sqrt((mueff-1)/(N+1))-1) + cs; % damping for sigma 
                                                      % usually close to 1
  %% Initialize dynamic (internal) strategy parameters and constants
  pc = zeros(N,1); ps = zeros(N,1);   % evolution paths for C and sigma
  B = eye(N,N);                       % B defines the coordinate system
  D = ones(N,1);                      % diagonal D defines the scaling
  C = B * diag(D.^2) * B';            % covariance matrix C
  invsqrtC = B * diag(D.^-1) * B';    % C^-1/2 
  eigeneval = 0;                      % track update of B and D
  chiN=N^0.5*(1-1/(4*N)+1/(21*N^2));  % expectation of 
                                      %   ||N(0,I)|| == norm(randn(N,1))
  out.dat = []; out.datx = [];  % for plotting output

  %% -------------------- Generation Loop --------------------------------
  %% -------------------- Generation Loop --------------------------------
  %% -------------------- Generation Loop --------------------------------
  counteval = 0;  % the next 40 lines contain the 20 lines of interesting code 
  while counteval < stopeval
    fprintf('Current number of fun.evals: %d\n',counteval)
    %% Generate and evaluate lambda offspring
    for k=1:lambda,
      arx(:,k) = xmean + sigma * B * (D .* randn(N,1)); % m + sig * Normal(0,C) 
      % <normalize x>
      arx(:,k) = arx(:,k)/norm(arx(:,k));
      % </normalize x>
      arfitness(k) = feval(strfitnessfct, arx(:,k)); % objective function call
      counteval = counteval+1;
    end
    
    %% Sort by fitness and compute weighted mean into xmean
    [arfitness, arindex] = sort(arfitness);  % minimization
    xold = xmean;
    xmean = arx(:,arindex(1:mu)) * weights;  % recombination, new mean value
    
    %% Cumulation: Update evolution paths
    ps = (1-cs) * ps ... 
          + sqrt(cs*(2-cs)*mueff) * invsqrtC * (xmean-xold) / sigma; 
    hsig = sum(ps.^2)/(1-(1-cs)^(2*counteval/lambda))/N < 2 + 4/(N+1);
    pc = (1-cc) * pc ...
          + hsig * sqrt(cc*(2-cc)*mueff) * (xmean-xold) / sigma; 

    %% Adapt covariance matrix C
    artmp = (1/sigma) * (arx(:,arindex(1:mu)) - repmat(xold,1,mu));  % mu difference vectors
    C = (1-c1-cmu) * C ...                   % regard old matrix  
         + c1 * (pc * pc' ...                % plus rank one update
                 + (1-hsig) * cc*(2-cc) * C) ... % minor correction if hsig==0
         + cmu * artmp * diag(weights) * artmp'; % plus rank mu update 

    %% Adapt step size sigma
    sigma = sigma * exp((cs/damps)*(norm(ps)/chiN - 1)); 
    
    %% Update B and D from C
    if counteval - eigeneval > lambda/(c1+cmu)/N/10  % to achieve O(N^2)
      eigeneval = counteval;
      C = triu(C) + triu(C,1)'; % enforce symmetry
      [B,D] = eig(C);           % eigen decomposition, B==normalized eigenvectors
      D = sqrt(diag(D));        % D contains standard deviations now
      invsqrtC = B * diag(D.^-1) * B';
    end
    
    disp('Saving temporal solution');
    esWeights = arx(:, arindex(1)) % Return best point of last iteration.
    save(savename); 
    
    
    %% Break, if fitness is good enough or condition exceeds 1e14, better termination methods are advisable 
    if arfitness(1) <= stopfitness || max(D) > 1e7 * min(D)
      break;
    end

    %% Output 
    more off;  % turn pagination off in Octave
    disp([num2str(counteval) ': ' num2str(arfitness(1)) ' ' ... 
          num2str(sigma*sqrt(max(diag(C)))) ' ' ...
          num2str(max(D) / min(D))]);
    % with long runs, the next line becomes time consuming
    out.dat = [out.dat; arfitness(1) sigma 1e5*D' ]; 
    out.datx = [out.datx; xmean'];
  end % while, end generation loop

  %% ------------- Final Message and Plotting Figures --------------------
  disp([num2str(counteval) ': ' num2str(arfitness(1))]);
  xmin = arx(:, arindex(1)); % Return best point of last iteration.
                             % Notice that xmean is expected to be even
                             % better.
  figure(1); hold off; semilogy(abs(out.dat)); hold on;  % abs for negative fitness
  semilogy(out.dat(:,1) - min(out.dat(:,1)), 'k-');  % difference to best ever fitness, zero is not displayed
  title('fitness, sigma, sqrt(eigenvalues)'); grid on; xlabel('iteration');  
  figure(2); hold off; plot(out.datx); 
  title('Distribution Mean'); grid on; xlabel('iteration')
  
  esWeights=xmin;
  save(savename); 
%% ---------------------------------------------------------------  


