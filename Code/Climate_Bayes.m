% Bayesian Variable Selection Model with
% Recursive Estimation Method

clc;clear;
addpath('/Users/johnnycho/Documents/MATLAB/M_library')

rng(123)

%% Data load
%Data_Full = readmatrix('Data_climate_total.xlsx', 'Sheet', 'Sheet1', 'Range','B2:T106');
Data_Full = readmatrix('Data_climate_cluster6_00.xlsx', 'Sheet', 'Sheet1', 'Range','B2:Z106');
Data_Full = horzcat(Data_Full(:,1:5), Data_Full(:,8:end)); % 가변수 제거 

% 전처리. z-normalization. (train).fit_transform / (test).transform

OSS = 15; % 105개 샘플 중 15개를 out of sample period로 지정. 
Prediction_Errorm = zeros(OSS, 1);

k = size(Data_Full, 2); % column 개수.
Post_Probm = zeros(OSS, k+1); % k+1 = n(상수항, y_t, x_1t, .., x_kt)
Forecast_Valuem = zeros(OSS,1);

n = 10000; % simulation size
Y_fmm = zeros(OSS, n); % Y 예측치를 모아놓은 행렬.

for ind_oss = 1:OSS
    realized_y = Data_Full(end-ind_oss+1,1); % realized value
    
    Data = Data_Full(1:end-ind_oss,:); % Recursive Estimation Method
    %Data = Data_Full(ind_oss:90+ind_oss,:); % Rolling window
    
    h = 4; % h=1,2,3,4: h-period ahead forecast
    Y = Data(1+h:end,1); % dependent variable y_(t+h)
    T = rows(Y); % sample size
    X = [ones(T,1), Data(1:end-h,:)]; % regressors, y_t + x1_t + ... 
    x_T = [1; Data(end-h+1, 1:end)']; % 마지막 data.
    
    
    %% Estimation: Markov Chain Monte Carlo(MCMC) Simulation
    
    % hyperparameters setting
    K = size(X,2);
    p = 0.5; 
    
    % prior for beta
    b0 = 10^(-6);
    b1 = 2^(7);
    beta0 = zeros(K,1);
    
    % prior for sigma2
    alpha0 = 5;
    delta0 = 5;
    
    % initial values
    gamma = ones(K,1);
    sigma2 = delta0/(alpha0-2); % prior mean of sigma2
    
    %n = 10000; % simulation size
    betam = zeros(n, K);
    Sigm = zeros(n,1);
    Gammam = zeros(n, K);
    Y_fm = zeros(n,1);
    
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
        y_T1 = (x_T)'*beta+sqrt(sigma2)*randn(1,1); % predictive sample
        Y_fm(iter)=y_T1;
        
    end
    
    Y_fmm(ind_oss, :) = Y_fm;
    
    forecast = meanc(Y_fm); % forecast = posterior mean
    Forecast_Valuem(ind_oss,:) = forecast;
    
    prediction_error = realized_y - forecast;
    disp(['     prediction error is ',num2str(prediction_error)])
    disp('=====================================')
    
    Prediction_Errorm(ind_oss) = prediction_error;
    Post_Prob1 = meanc(Gammam); % importance of each regressors
    
%     disp(Post_Prob1);
    Post_Probm(ind_oss,:) = Post_Prob1'; % 변수 중요도 행렬에 저장. 

%     figure(ind_oss)
%     x = 1:K;
%     scatter(x, Post_Prob1, 'filled')
%     xlim([0.5 K+0.5])
%     ylim([-0.1, 1.1])
%     grid on

    
end

squared_errors = Prediction_Errorm'*Prediction_Errorm; % 1 by 1
RMSE = sqrt((squared_errors)/OSS);
disp(['     RMSE is ',num2str(RMSE)])
disp('=====================================')

% Save as csv
% writematrix(Post_Probm,'Cluster6_Post_Probm_00.csv') 
% writematrix(Forecast_Valuem,'Cluster6_Forecast_Valuem_00.csv') % Forecast value(sample averaged)
% writematrix(Y_fmm, 'Cluster6_Yfmm_00.csv') % Forecast value matrix(not averaged)




