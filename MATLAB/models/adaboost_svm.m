function [yhat,WE,B] = adaboost(X, y)
% ADABoost demo using SVM

% define and plot the data
ell = length(y);
hold off
plot(X(y==1,1),X(y==1,2),'b*',X(y==-1,1),X(y==-1,2),'r*')
% initialize the weight vector
we = ones(ell,1)/ell;
cw = ones(ell,1)*1000; % weight we would have used in our SVM classifier
t = 1; T = 1000;
while (t < T) % perhaps we should have a maximum step size
    % Bagging, sample with replacement with probability we training data
    I = randsample(ell,ell,true,we);
    Xt = X(I,:); yt = y(I);
    % Use the Support Vector Machine (SVM) to find (w,b) classifier
    [w,b] = svm_l1(Xt,yt,cw);
    
    hold on
    if ~all(w==0) % display the SVM plane at zero
      x1(1) = 10;   x2(2) = 10; x2(1) = (-b-w(1)*x1(1))/w(2);  x1(2) = (-b-w(2)*x2(2))/w(1);
      plot(x1,x2,':'), shg, pause(0.5), set(gca,'ylim',[0 10],'xlim',[0 10])      
    else
        % now this is a rather silly stop critera, but what the ...
        break;
    end
    % the pseudocode for this may be found here:http://en.wikipedia.org/wiki/AdaBoost
    error(t) = sum(-y.*sign(X*w+b).*we); % the weighted error
    alpha(t) = (1/2)*log((1-error(t))/(1+error(t))); % update on alpha
    we = we.*exp(-alpha(t)*y.*sign(X*w+b)); % update the weights
    we = we/sum(we); % and normalize probabilities
    WE(t,:) = we; W(t,:) = w; B(t) = b; % keep esemble and history of weights used
    t = t + 1;    
end
% now classify your complete data set or some test set using esemble model
for t = 1:length(alpha)
    yhatall(:,t)=alpha(t)*sign(X*W(t,:)'+B(t));
end
yhat = sign(sum(yhatall,2));
end
