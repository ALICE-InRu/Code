function model = jssp_gurobi_model(p,sigma)
% JSSP_GUROBI_MODEL (minimize makespan)
% Usage: model = jssp_gurobi_model(p,sigma)
% Example:
%  % permutation of the machines, which represents the processing order
%  % of j through the machines: j must be processed first on sigma[j,1],
%  % then on sigma[j,2], etc. sigma must be permutation
%
%sigma = [ 3  1  2  4  6  5
%    2  3  5  6  1  4
%    3  4  6  1  2  5
%    2  1  3  4  5  6
%    3  2  5  6  1  4
%    2  4  6  1  5  3] ;
%  % processing time of j on a
%p = [    3  6  1  7  6  3
%    10  8  5  4 10 10
%    9  1  5  4  7  8
%    5  5  5  3  8  9
%    3  3  9  1  5  4
%    10  3  1  3  4  9] ;
%
%model = jssp_gurobi_model(p,sigma)
%
% % gurobi_write(model, 'jssp.lp');
%    
%clear params;
%params.outputflag = 0;
%    
%result = gurobi(model, params);
%    
%disp(result)
%   
%for v=1:length(model.varnames)
%   fprintf('%s %d\n', model.varnames{v}, result.x(v));
%end
%    
%fprintf('Obj: %.4g\n', result.objval);

% number of jobs
n = size(sigma,1);

% number of machines
m = size(sigma,2);

% var x{j in J, a in M}, >= 0;
x_start = 0;
for j=1:n
    for a=1:m
        index = sub2ind([n m],j,a);
        names(x_start + index) = {sprintf('X(%d,%d)',j,a)};
    end
end
vtype = repmat('C',1,n*m);
N = n*m;
% var Y{i in J, j in J, a in M}, binary;
y_start = N;
for i=1:n
    for j=1:n
        for a=1:m
            index = sub2ind([n n m], i, j, a);
            names(y_start + index) = {sprintf('Y(%d,%d,%d)',i,j,a)};
        end
    end
end
vtype = [vtype repmat('B',1,n*n*m)];
N = N + n*n*m;
% so-called makespan
z_start = N;
names(z_start+1) = {'Z'};
vtype = [vtype 'C'];
N = N + 1;

% starting time of j on a
% s.t. ord{j in J, t in 2..m}:
% j can be processed on sigma[j,t] only after it has been completely
%   processed on sigma[j,t-1]
counter = 0;
A = sparse(1,N);
for j=1:n
    for t=2:m
        counter = counter + 1;
        % x[j, sigma[j,t]] >= x[j, sigma[j,t-1]] + p[j, sigma[j,t-1]];
        %  -x[j, sigma[j,t-1]]  + x[j, sigma[j,t]] >= p[j, sigma[j,t-1]];
        index = sub2ind([n m], j, sigma(j,t-1));
        A(counter,x_start + index) = -1;
        index = sub2ind([n m],j, sigma(j,t));
        A(counter,x_start + index) = 1;
        b(counter) = p(j,sigma(j,t-1));
        sense(counter) = '>';
    end
end

% The disjunctive condition that each machine can handle at most one
%   job at a time is the following:
%
%      x[i,a] >= x[j,a] + p[j,a]  or  x[j,a] >= x[i,a] + p[i,a]
%
%   for all i, j in J, a in M. This condition is modeled through binary
%   variables Y as shown below. */


% Y[i,j,a] is 1 if i scheduled before j on machine a, and 0 if j is
%   scheduled before i */

% some large constant
K = sum(p(:));

%s.t. phi{i in J, j in J, a in M: i < j}:
%      x[i,a] >= x[j,a] + p[j,a] - K * Y[i,j,a];
%/* x[i,a] >= x[j,a] + p[j,a] iff Y[i,j,a] is 0 */

for i=1:n
    for j=(i+1):n
        for a = 1:m
            % x[i,a] - x[j,a] +  K * Y[i,j,a] >=  p[j,a] ;
            counter = counter + 1;
            index = sub2ind([n m],i,a);
            A(counter,x_start+index) = 1;
            index = sub2ind([n m],j,a);
            A(counter,x_start+index) = -1;
            index = sub2ind([n n m], i, j,a);
            A(counter,y_start+index) = K;
            b(counter) = p(j,a);
            sense(counter) = '>';
        end
    end
end

%s.t. psi{i in J, j in J, a in M: i < j}:
%      x[j,a] >= x[i,a] + p[i,a] - K * (1 - Y[i,j,a]);
%/* x[j,a] >= x[i,a] + p[i,a] iff Y[i,j,a] is 1 */

for i=1:n
    for j=(i+1):n
        for a = 1:m
            %     x[j,a] - x[i,a] - K Y[i,j,a] >=  + p[i,a] - K ;
            counter = counter + 1;
            index = sub2ind([n m],j,a);
            A(counter,x_start+index) = 1;
            index = sub2ind([n m],i,a);
            A(counter,x_start+index) = -1;
            index = sub2ind([n n m], i, j, a);
            A(counter,y_start+index) = -K;
            b(counter) = p(i,a) - K;
            sense(counter) = '>';
        end
    end
end

%s.t. fin{j in J}: z >= x[j, sigma[j,m]] + p[j, sigma[j,m]];
%/* which is the maximum of the completion times of all the jobs */
for j=1:n
    counter = counter + 1;
    % z - x[j, sigma[j,m]] >=  p[j, sigma[j,m]];
    A(counter,z_start+1) = 1;
    index = sub2ind([n m], j, sigma(j,m));
    A(counter,x_start+index) = -1;
    b(counter) = p(j,sigma(j,m));
    sense(counter) = '>';
end


% minimize obj: z;
% the objective is to make z as small as possible */
c = zeros(1,N);
c(z_start+1) = 1;

model.A = A;
model.obj = c;
model.rhs = b;
model.sense = sense;
model.vtype = vtype;
model.modelsense = 'min';
model.varnames = names;
model.lb = zeros(1,N);