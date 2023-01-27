% Bayesian Variable Selection Model with
% Recursive Estimation Method
% h=1,2,3,4

clc;clear;
addpath('/Users/johnnycho/Documents/MATLAB/M_library')

rng(123)
%% Data load
%Data_Full = readmatrix('Data_climate_total.xlsx', 'Sheet', 'Sheet1', 'Range','B2:T106');
Data_Full = readmatrix('Data_climate_cluster6_11.xlsx', 'Sheet', 'Sheet1', 'Range','B2:Z106');
Data_Full = horzcat(Data_Full(:,1:5), Data_Full(:,8:end)); % 가변수 제거

% Data_Full1 = horzcat(Data_Full(1:4:420, 1:2), Data_Full(1:4:420, 5:end));
% Data_Full2 = horzcat(Data_Full(2:4:420, 1:2), Data_Full(1:4:420, 5:end));
% Data_Full3 = horzcat(Data_Full(3:4:420, 1:2), Data_Full(1:4:420, 5:end));
% Data_Full4 = horzcat(Data_Full(4:4:420, 1:2), Data_Full(1:4:420, 5:end));

Data_chosen = Data_Full;

X_T = [1; Data_chosen(end, 1:end)']; % t = T

ind_oss = 1; % Full dataset 사용

realized_y = Data_chosen(end-ind_oss+1,1); % realized value

Data = Data_chosen(1:end-ind_oss,:); % Recursive Estimation Method

H = 4;
n = 10000; % simulation size

k = size(Data_Full, 2);
Post_Probm = zeros(H, k+1);

Y_fmm = zeros(H, n);
Forecast_Valuem = zeros(H, 1);

b0m = [10^(-6), 10^(-6), 10^(-5), 10^(-4)]; % best hyperparameter for 11
%b0m = [10^(-6), 10^(-4), 10^(-6), 10^(-5)]; % best hyperparameter for 00

for h = 1:H % h=1,2,3,4
    % h =1
    Y = Data(1+h:end,1); % dependent variable y_(t+h)
    T = rows(Y); % sample size
    X = [ones(T,1), Data(1:end-h,:)]; % regressors, y_t + x1_t + ...
    
    %% Estimation: Markov Chain Monte Carlo(MCMC) Simulation
    
    % hyperparameters setting
    K = size(X,2);
    p = 0.5; % p=0.5: Bayesian Variable Selection
    
    % prior for beta
    b0 = b0m(:,h);
    b1 = 2^(7);
    beta0 = zeros(K,1);
    
    % prior for sigma2
    alpha0 = 5;
    delta0 = 5;
    
    % initial values
    gamma = ones(K,1);
    sigma2 = delta0/(alpha0-2); % prior mean of sigma2
    
    n = 10000; % simulation size
    betam = zeros(n, K);
    Sigm = zeros(n,1);
    Gammam = zeros(n, K);
    Y_FM = zeros(n,1); % to forecast Y_(T+h).
    
    for iter = 1:n
        
        %% sampling beta
        B0 = diag(gamma*b1+(1-gamma)*b0); % K by K
        B1 = inv((1/sigma2)*X'*X+inv(B0));
        beta1 = B1*((1/sigma2)*X'*Y+inv(B0)*beta0);
        beta = beta1 + chol(B1)'*randn(K,1);
        
        betam(iter, :)=beta'; % 1 by k;
        
        %% sampling sigma2
        alpha1 = alpha0 + T;
        delta1 = delta0 + (Y-X*beta)'*(Y-X*beta);
        sigma2 = randig(alpha1/2, delta1/2);
        
        Sigm(iter,1)=sigma2;
        
        %% sampling Gamma
        for i = 1:K
            pr1 = exp(lnpdfn(beta(i), 0, b1))*p;
            pr0 = exp(lnpdfn(beta(i), 0, b0))*(1-p);
            Prb1 = pr1 / (pr1+pr0);
            u = rand(1,1);
            if u < Prb1
                gamma(i) = 1;
            else
                gamma(i) = 0;
            end
            
        end
        
        Gammam(iter, :) = gamma'; % 1 by K
        
        %% sampling predictive distribution
        y_T1 = (X_T)'*beta+sqrt(sigma2)*randn(1,1); % to predict Y_(T+h)
        Y_FM(iter)=y_T1;
        
    end
    
    % figure(1)
    % histogram(Y_FM)
    % title(['Forecasts'])
    forecast = meanc(Y_FM);
    %Forecast_Valuem(1,:) = forecast;
    
    Post_Prob1 = meanc(Gammam); % importance of each regressors
    
    % figure(2)
    % x = 1:K;
    % scatter(x, Post_Prob1, 'filled')
    % xlim([0.5 K+0.5])
    % ylim([-0.1, 1.1])
    % grid on
    Y_fmm(h,:) = Y_FM;
    Post_Probm(h,:) = Post_Prob1;
    Forecast_Valuem(h,:) = forecast;
    
    
end

% Save as csv
% writematrix(Y_fmm,'Forecast_Yfmm_11.csv')
% writematrix(Forecast_Valuem,'Forecast_Valuem_11.csv') % Forecast value(sample averaged)
% writematrix(Post_Probm,'Forecast_Post_Probm_11.csv')




