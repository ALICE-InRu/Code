clear all, close all
% Simulation of a M/M/1 queue:
mean_interarrival = 1.0;
mean_service = 0.9;
% special symbols
omega = 1/mean_service;
lambda = 1/mean_interarrival;
% number of servers is one
rho = lambda / (1*omega)
% the initial delay is
s = 0; % use either s = [20 18 15 12 10 5 0] % see fig. 9.2
% redo the experiment a number of times
for j = 1:500,
  % delay in queue, initial condition
  D(j,1) = s; 
  % service time for first customer arriving at time 0
  S(1) = -mean_service * log(rand(1)); % Expon
  % loop through 1000 customers arriving
  for i = 1:479, % see figure 9.2
    % the interattical time of the next customer
    A(i+1) = -mean_interarrival * log(rand(1)); % Expon
    % compute the delay
    D(j,i+1) = max([0, D(j,i) + S(i) - A(i+1)]);
    % assign service time
    S(i+1) = -mean_service * log(rand(1)); % Expon
  end
end
% plot this result
plot(mean(D)), ylabel('E(D)'); xlabel('i'); title('figure 9.2'); grid
hold on
plot(mean(D)+std(D),':'), ylabel('E(D)'); xlabel('i'); title('figure 9.2'); grid
plot(mean(D)-std(D),':'), ylabel('E(D)'); xlabel('i'); title('figure 9.2'); grid

% Estimating means section 9.4.1
% alpha = 1 - gamma = 0.1, t_(n-1),(1-\alpha/2)
% tval =[2.132 1.833 1.729 1.684];
% or use tinv(0.95,n-1) n = [5 10 20 40]
clear all
mean_interarrival = 1.0;
mean_service = 0.9;
% redo the experiment a number of times
n = 10; % example using n = 10 [5 10 20 40]
tval = tinv(0.95, n-1) % t-value at 1 - alpha/2
for k = 1:500,
  for j = 1:n,
    % delay in queue, initial condition
    D(j,1) = 0; 
  % service time for first customer arriving at time 0
    S(1) = -mean_service * log(rand(1)); % Expon
    % loop through 1000 customers arriving
    for i = 1:24, %
      % the interattical time of the next customer
      A(i+1) = -mean_interarrival * log(rand(1)); % Expon
      % compute the delay
      D(j,i+1) = max([0, D(j,i) + S(i) - A(i+1)]);
      % assign service time
      S(i+1) = -mean_service * log(rand(1)); % Expon
    end
  end
  d = sum(D,2)/25;
  d25(k,1) = mean(d);
  var25(k,1) = var(d); % for estimating number of replications needed
  confinterval(k,1) = tval * sqrt(var(d)/n);
end
p = ((d25 - confinterval <= 2.12) & (2.12 <= (d25 + confinterval)));
% the result as shown in figure 9.2
n
pm = mean(p)
pmconf = norminv(0.95, 0, 1) * sqrt(pm*(1-pm)/500)
conf_interval_half_length = mean(confinterval./d25)

% estimate the number of replications needed to get certain confidence:
gamma = 0.1;
gammad = gamma/(1+gamma);
nstar = ceil(mean(var25) * (norminv(0.95, 0, 1) / (gammad*mean(d25)))^2)
beta = gamma*mean(d25)
mean(confinterval) 