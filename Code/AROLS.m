function [beta, Sig2, Cov, U] =AROLS(y, p)
T = size(y,1); % count number of rows(number of observations)
Y = y(p+1:T,1); % y(p+1), ..., y(T)
X = ones(T-p,1);
for j = 1:p
    X = [X, y(p+1-j:T-j,1)]; % recursive하게 stacking?
end
beta = inv(X'*X)*(X'*Y); % (X'*X)\(X '*Y) = inv(X'*X)*(X'*Y)
U = Y - X*beta;
Sig2 = (U'*U)/(T-p-1); % For Unbiasedness: T-p-1
Cov = Sig2*inv(X'*X);
end
