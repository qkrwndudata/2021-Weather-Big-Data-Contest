% ADL model
% Recursive Estimation Method

clc;clear;
addpath('/Users/johnnycho/Documents/MATLAB/M_library')

rng(123)
%% Data load
%Data_Full = readmatrix('Data_climate_total.xlsx', 'Sheet', 'Sheet1', 'Range','B2:T106');
Data_Full = readmatrix('Data_climate_cluster6_11.xlsx', 'Sheet', 'Sheet1', 'Range','B2:AC106');

% Data_Full1 = horzcat(Data_Full(1:4:420, 1:2), Data_Full(1:4:420, 5:end));
% Data_Full2 = horzcat(Data_Full(2:4:420, 1:2), Data_Full(1:4:420, 5:end));
% Data_Full3 = horzcat(Data_Full(3:4:420, 1:2), Data_Full(1:4:420, 5:end));
% Data_Full4 = horzcat(Data_Full(4:4:420, 1:2), Data_Full(1:4:420, 5:end));

Data_chosen = Data_Full;

% AR estimation: y_t = y_(t-1) + x_t + u_t
% RMSE 계산하기.
y = Data_Full(:,1);
%x = Data_Full(:, 3); % strongly exogenous variable: qty_drink

OSS = 15;
Prediction_Errorm = zeros(OSS, 1);

for ind_oss = 1:OSS
    
    realized_y = Data_Full(end-ind_oss+1,1); % realized value
    
    Data = Data_Full(1:end-ind_oss,:); % recursive estimation method
    
    h = 4; % time horizon. h=1,2,3,4
    Y = Data(1+h:end,1); % dependent variable, y_(t+h)
    %x = Data(1:end-h,3); % independent variable, x_t
    T = rows(Y); % sample size 
    X = [ones(T-1,1), Y(1:T-1,1)]; % regressors: x_t, y_t
    Y_T = Data(end, 1); % observations used in prediction
    %CA_T = Data(end, 3); 
    x_T = [1; Y_T]; % last data
    [beta, Sig2, Cov, U] = AROLS(Y, 1); % AR(1)
    
    n = 10000; % simulation size
    Y_fm = zeros(n,1);
    
    for iter=1:n
        y_T1 = (x_T)'*beta+sqrt(Sig2)*randn(1,1); % predictive sample
        Y_fm(iter) = y_T1;
    end
    forecast = meanc(Y_fm); % forecast = posterior mean
    prediction_error = realized_y - forecast;
    disp(['     prediction error is ',num2str(prediction_error)])
    disp('=====================================')
    
    Prediction_Errorm(ind_oss) = prediction_error;
    
end

squared_errors = Prediction_Errorm'*Prediction_Errorm; % 1 by 1
RMSE = sqrt((squared_errors)/OSS);
disp(['     RMSE is ',num2str(RMSE)])
disp('=====================================')

