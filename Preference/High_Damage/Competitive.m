%%%%% This file generates results for the Competitive model SCC results.
% Authors: Mike Barnett, Jieyao Wang
% Last update: Sep 27,2019
close all
clear all
clc

%% Step 0: set up solver
%%%%% change to location of the solver
addpath('/mnt/ide0/home/wangjieyao/Climate/FT/')
addpath('/home/wangjieyao/FT/')
addpath('/Volumes/homes/FT/')

%% Step 1: Set up parameters

McD = csvread('TCRE_MacDougallEtAl2017_update.csv');
McD = McD./1000;
par_lambda_McD = McD(:,1);
beta_f = mean(par_lambda_McD); 
var_beta_f = var(par_lambda_McD);
lambda = 1./var_beta_f;
delta = 0.01;
alpha= 0.032;
sigma_g = 0.02;
sigma_k = 0.0161;
sigma_r = 0.0339;
A_O = 0.115000000000000;
Gamma = 0.0600;
Theta = 1./16.666666666666668;
Alpha = -0.034977443912449;
Gamma_r = 0.112733407891680;
Theta_r = 0.142857142857143;
power = 2;
gamma_1 =  0.00017675;
gamma_2 =  2.*0.0022;
gamma_2_plus = 2.*0.0197;
sigma_1 = 0;
sigma_2 = 0;
rho_12 = 0;
f_bar = 2;
crit = 2;
F0 = 1;
sigma = [sigma_1.^2, rho_12; rho_12, sigma_2.^2];
Sigma = [var_beta_f,0,0;0,sigma_1.^2, rho_12; 0, rho_12, sigma_2.^2];
dee = [gamma_1 + gamma_2.*F0+gamma_2_plus.*(F0-f_bar).^2.*(F0>=2),beta_f,beta_f.*F0];
sigma_d = sqrt(dee*Sigma*dee');
xi_d = -1.*(1-alpha);

s0 = '/climate_pars';
filename = [pwd, s0];
save(filename); % save parameters


weight = 0.0; % weight on nordhaus
bar_gamma_2_plus = weight.*0+(1-weight).*gamma_2_plus;

theta = 4500; % ambiguity parameter

%% Step 2: solve HJB for planner's problem
r_min = 0;
r_max = 12; %r = logR
t_min = 0;
t_max = 4000;
k_min = 0;
k_max = 12; %k = logK
nr = 30;
nt = 40;
nk = 25;
r = linspace(r_min,r_max,nr)';
t = linspace(t_min,t_max,nt)';
k = linspace(k_min,k_max,nk)';
hr = r(2) - r(1);
hk = k(2) - k(1);
ht = t(2) - t(1);
[r_mat,t_mat,k_mat] = ndgrid(r,t,k); 

quadrature = 'legendre';
n = 30;
a = beta_f-5.*sqrt(var_beta_f);
b = beta_f+5.*sqrt(var_beta_f);

tol = 1e-16; % tol
dt = 0.5; % epsilon
v0 = (alpha).*r_mat+(1-alpha).*k_mat-beta_f.*t_mat; % initial guess
v1_initial = v0.*ones(size(r_mat));
out = v0;
vold = v0 .* ones(size(v0));
iter = 1;

v0 = v0.*ones(size(v0));
v0 = reshape(out,size(v0));

v0_dt = zeros(size(v0));
v0_dt(:,2:end-1,:) = (1./(2.*ht)).*(v0(:,3:end,:)-v0(:,1:end-2,:));
v0_dt(:,end,:) = (1./ht).*(v0(:,end,:)-v0(:,end-1,:));
v0_dt(:,1,:) = (1./ht).*(v0(:,2,:)-v0(:,1,:));

v0_dr = zeros(size(v0));
v0_dr(2:end-1,:,:) = (1./(2.*hr)).*(v0(3:end,:,:)-v0(1:end-2,:,:));
v0_dr(end,:,:) = (1./hr).*(v0(end,:,:)-v0(end-1,:,:));
v0_dr(1,:,:) = (1./hr).*(v0(2,:,:)-v0(1,:,:));
v0_dr(v0_dr<1e-8) = 1e-8;

v0_dk = zeros(size(v0));
v0_dk(:,:,2:end-1) = (1./(2.*hk)).*(v0(:,:,3:end)-v0(:,:,1:end-2));
v0_dk(:,:,end) = (1./hk).*(v0(:,:,end)-v0(:,:,end-1));
v0_dk(:,:,1) = (1./hk).*(v0(:,:,2)-v0(:,:,1));

v0_drr = zeros(size(v0));
v0_drr(2:end-1,:,:) = (1./(hr.^2)).*(v0(3:end,:,:)+v0(1:end-2,:,:)-2.*v0(2:end-1,:,:));
v0_drr(end,:,:) = (1./(hr.^2)).*(v0(end,:,:)+v0(end-2,:,:)-2.*v0(end-1,:,:));
v0_drr(1,:,:) = (1./(hr.^2)).*(v0(3,:,:)+v0(1,:,:)-2.*v0(2,:,:));

v0_dtt = zeros(size(v0));
v0_dtt(:,2:end-1,:) = (1./(ht.^2)).*(v0(:,3:end,:)+v0(:,1:end-2,:)-2.*v0(:,2:end-1,:));
v0_dtt(:,end,:) = (1./(ht.^2)).*(v0(:,end,:)+v0(:,end-2,:)-2.*v0(:,end-1,:));
v0_dtt(:,1,:) = (1./(ht.^2)).*(v0(:,3,:)+v0(:,1,:)-2.*v0(:,2,:));

v0_dkk = zeros(size(v0));
v0_dkk(:,:,2:end-1) = (1./(hk.^2)).*(v0(:,:,3:end)+v0(:,:,1:end-2)-2.*v0(:,:,2:end-1));
v0_dkk(:,:,end) = (1./(hk.^2)).*(v0(:,:,end)+v0(:,:,end-2)-2.*v0(:,:,end-1));
v0_dkk(:,:,1) = (1./(hk.^2)).*(v0(:,:,3)+v0(:,:,1)-2.*v0(:,:,2));

% FOC
B1 = v0_dr-xi_d.*(gamma_1(1)+gamma_2(1)*(t_mat).*beta_f+gamma_2_plus(1).*(t_mat.*beta_f-f_bar).^(power-1).*(t_mat>=(crit./beta_f))) ...
    .*beta_f.*exp(r_mat)-v0_dt.*exp(r_mat);  
C1 = -delta.*alpha;
e = -C1./B1;
e_hat = e;

Acoeff = ones(size(r_mat));
Bcoeff = ((delta.*(1-alpha)./Theta+Gamma./Theta.*v0_dk).*delta.*(1-alpha)./(v0_dr.*Gamma_r.*0.5)...
    .*exp(0.5.*(r_mat-k_mat)))./(delta.*(1-alpha)./Theta);
Ccoeff = -A_O - Theta;
f = ((-Bcoeff+sqrt(Bcoeff.^2 - 4.*Acoeff.*Ccoeff))./(2.*Acoeff)).^(2);
i_k = A_O-f-(delta.*(1-alpha))./(v0_dr.*Gamma_r.*0.5).*f.^0.5.*exp(0.5.*(r_mat-k_mat));

% update prob.
a_1 = zeros(size(r_mat));
b_1 = xi_d.*e_hat.*exp(r_mat).*gamma_1;
c_1 = 2.*xi_d.*e_hat.*exp(r_mat).*t_mat.*gamma_2;
lambda_tilde_1 = lambda+c_1.*theta;
beta_tilde_1 = beta_f-c_1.*theta./lambda_tilde_1.*beta_f-theta./lambda_tilde_1.*b_1;
I_1 = a_1-0.5.*log(lambda)./theta + 0.5.*log(lambda_tilde_1)./theta ...
    +0.5.*lambda.*beta_f.^2./theta -0.5.*lambda_tilde_1.*(beta_tilde_1).^2./theta;
J_1_without_e = xi_d.*(gamma_1.*beta_tilde_1 ...
    +gamma_2.*t_mat.*(beta_tilde_1.^2+1./lambda_tilde_1)).*exp(r_mat) ;
pi_tilde_1 = weight.*exp(-theta.*I_1);

scale_2_fnc = @(x) exp(-theta.*xi_d.*(gamma_1.*x ...
    +gamma_2.*x.^2.*t_mat ...
    +gamma_2_plus.*x.*(x.*t_mat-f_bar).^(power-1).*((x.*t_mat-f_bar)>=0)).*exp(r_mat).*e_hat) ...
    .*normpdf(x,beta_f,sqrt(var_beta_f));
scale_2 = quad_int(scale_2_fnc, [a], [b], n, 'legendre'); % quadrature
q2_tilde_fnc = @(x) exp(-theta.*xi_d.*(gamma_1.*x ...
    +gamma_2.*x.^2.*t_mat ...
    +gamma_2_plus.*x.*(x.*t_mat-f_bar).^(power-1).*((x.*t_mat-f_bar)>=0)).*exp(r_mat).*e_hat)./scale_2;
I_2 = -1./theta.*log(scale_2);
J_2_without_e_fnc = @(x) xi_d.*exp(r_mat).*...
    q2_tilde_fnc(x) ...
    .*(gamma_1.*x +gamma_2.*t_mat.*x.^2 ...
    +gamma_2_plus.*x.*(x.*t_mat-f_bar).^(power-1).*((x.*t_mat-f_bar)>=0)) ...
    .*normpdf(x,beta_f,sqrt(var_beta_f));
J_2_without_e = quad_int(J_2_without_e_fnc, [a], [b], n,'legendre'); % quadrature
J_2_with_e = J_2_without_e.*e_hat;
pi_tilde_2 = (1-weight).*exp(-theta.*I_2);
pi_tilde_1_norm = pi_tilde_1./(pi_tilde_1+pi_tilde_2);
pi_tilde_2_norm = 1-pi_tilde_1_norm;  
    
expec_e_sum = (pi_tilde_1_norm.*(J_1_without_e) ...
    +pi_tilde_2_norm.*(J_2_without_e));
B1 = v0_dr-v0_dt.*exp(r_mat)-expec_e_sum;  
C1 = -delta.*alpha;
e = -C1./B1; % FOC 
e_star = e; 

J_1 = J_1_without_e.*e_star;
J_2 = J_2_without_e.*e_star;
I_term = -1./theta.*log(pi_tilde_1+pi_tilde_2);
R_1 = theta.*(I_1 - J_1);     
R_2 = theta.*(I_2 - J_2);
drift_distort = (pi_tilde_1_norm.*J_1 ...
    +pi_tilde_2_norm.*J_2);   
if (weight == 0 || weight == 1)
    RE = pi_tilde_1_norm.*R_1 + pi_tilde_2_norm.*R_2;
else
    RE = pi_tilde_1_norm.*R_1 + pi_tilde_2_norm.*R_2 ...
        +pi_tilde_1_norm.*(log(pi_tilde_1_norm./weight)) ...
        +pi_tilde_2_norm.*(log(pi_tilde_2_norm./(1-weight)));        
end
RE_total = 1./theta.*RE;

% inputs for solver
A = -delta.*ones(size(r_mat));
B_r = -e_star+Gamma_r.*(f.^Theta_r).*exp(Theta_r.*(k_mat-r_mat))-0.5.*(sigma_r.^2);
B_k = Alpha+Gamma.*log(1+i_k./Theta)-0.5.*(sigma_k.^2);
B_t = e_star.*exp(r_mat);
C_rr = 0.5.*sigma_r.^2.*ones(size(r_mat));
C_kk = 0.5.*sigma_k.^2.*ones(size(r_mat));
C_tt = zeros(size(r_mat));

D = delta.*alpha.*log(e_star)+delta.*alpha.*r_mat ...
    + delta.*(1-alpha).*(log(A_O-i_k-f)+(k_mat)) ...
    + drift_distort + RE_total;      

stateSpace = [r_mat(:), t_mat(:), k_mat(:)]; 
model      = {};
model.A    = A(:); 
model.B    = [B_r(:), B_t(:), B_k(:)];
model.C    = [C_rr(:), C_tt(:), C_kk(:)];
model.D    = D(:);
model.v0   = v0(:);
model.dt   = dt;


out = solveCGNatural(stateSpace, model);
out_comp = reshape(out,size(v0)).*ones(size(r_mat));
    
disp(['Error: ', num2str(max(max(max(abs(out_comp - v1_initial)))))])
v0 = v0.*ones(size(v0));
v0 = reshape(out,size(v0));


while (max(max(max(abs(out_comp - vold))))) > tol % check for convergence
   tic
   vold = v0 .* ones(size(v0));

    v0_dt = zeros(size(v0));
    v0_dt(:,2:end-1,:) = (1./(2.*ht)).*(v0(:,3:end,:)-v0(:,1:end-2,:));
    v0_dt(:,end,:) = (1./ht).*(v0(:,end,:)-v0(:,end-1,:));
    v0_dt(:,1,:) = (1./ht).*(v0(:,2,:)-v0(:,1,:));

    v0_dr = zeros(size(v0));
    v0_dr(2:end-1,:,:) = (1./(2.*hr)).*(v0(3:end,:,:)-v0(1:end-2,:,:));
    v0_dr(end,:,:) = (1./hr).*(v0(end,:,:)-v0(end-1,:,:));
    v0_dr(1,:,:) = (1./hr).*(v0(2,:,:)-v0(1,:,:));
    v0_dr(v0_dr<1e-8) = 1e-8;

    v0_dk = zeros(size(v0));
    v0_dk(:,:,2:end-1) = (1./(2.*hk)).*(v0(:,:,3:end)-v0(:,:,1:end-2));
    v0_dk(:,:,end) = (1./hk).*(v0(:,:,end)-v0(:,:,end-1));
    v0_dk(:,:,1) = (1./hk).*(v0(:,:,2)-v0(:,:,1));

    v0_drr = zeros(size(v0));
    v0_drr(2:end-1,:,:) = (1./(hr.^2)).*(v0(3:end,:,:)+v0(1:end-2,:,:)-2.*v0(2:end-1,:,:));
    v0_drr(end,:,:) = (1./(hr.^2)).*(v0(end,:,:)+v0(end-2,:,:)-2.*v0(end-1,:,:));
    v0_drr(1,:,:) = (1./(hr.^2)).*(v0(3,:,:)+v0(1,:,:)-2.*v0(2,:,:));

    v0_dtt = zeros(size(v0));
    v0_dtt(:,2:end-1,:) = (1./(ht.^2)).*(v0(:,3:end,:)+v0(:,1:end-2,:)-2.*v0(:,2:end-1,:));
    v0_dtt(:,end,:) = (1./(ht.^2)).*(v0(:,end,:)+v0(:,end-2,:)-2.*v0(:,end-1,:));
    v0_dtt(:,1,:) = (1./(ht.^2)).*(v0(:,3,:)+v0(:,1,:)-2.*v0(:,2,:));

    v0_dkk = zeros(size(v0));
    v0_dkk(:,:,2:end-1) = (1./(hk.^2)).*(v0(:,:,3:end)+v0(:,:,1:end-2)-2.*v0(:,:,2:end-1));
    v0_dkk(:,:,end) = (1./(hk.^2)).*(v0(:,:,end)+v0(:,:,end-2)-2.*v0(:,:,end-1));
    v0_dkk(:,:,1) = (1./(hk.^2)).*(v0(:,:,3)+v0(:,:,1)-2.*v0(:,:,2));


    e_hat = e_star;
   
    f = ((delta.*(1-alpha)./Theta.*A_O-f.*delta.*(1-alpha)./Theta+delta.*(1-alpha)) ...
       ./(exp(Theta_r.*(r_mat-k_mat)).*(delta.*(1-alpha)./Theta+Gamma./Theta.*v0_dk).*delta.*(1-alpha)./(v0_dr.*Theta_r.*Gamma_r))) ...
       .^(1./(1-Theta_r));
    f = f.*(v0_dr>1e-8);

    i_k = (A_O-f-(delta.*(1-alpha))./(v0_dr.*Gamma_r.*Theta_r).*f.^(1-Theta_r).*exp(Theta_r.*(r_mat-k_mat))).*(v0_dr>1e-8)...
        + (v0_dr<=1e-8).*(v0_dk.*Gamma.*A_O - delta.*(1-alpha).*Theta)./(delta.*(1-alpha)+v0_dk.*Gamma);


    a_1 = zeros(size(r_mat));
    b_1 = xi_d.*e_hat.*exp(r_mat).*gamma_1;
    c_1 = 2.*xi_d.*e_hat.*exp(r_mat).*t_mat.*gamma_2;
    lambda_tilde_1 = lambda+c_1.*theta;
    beta_tilde_1 = beta_f-c_1.*theta./lambda_tilde_1.*beta_f-theta./lambda_tilde_1.*b_1;
    I_1 = a_1-0.5.*log(lambda)./theta + 0.5.*log(lambda_tilde_1)./theta ...
        +0.5.*lambda.*beta_f.^2./theta -0.5.*lambda_tilde_1.*(beta_tilde_1).^2./theta;
    R_1 = theta.*(I_1-(a_1+b_1.*beta_tilde_1+0.5.*c_1.*(beta_tilde_1).^2+0.5.*c_1./lambda_tilde_1));
    J_1_without_e = xi_d.*(gamma_1.*beta_tilde_1 ...
        +gamma_2.*t_mat.*(beta_tilde_1.^2+1./lambda_tilde_1)).*exp(r_mat) ;

    pi_tilde_1 = weight.*exp(-theta.*I_1);


    scale_2_fnc = @(x) exp(-theta.*xi_d.*(gamma_1.*x ...
        +gamma_2.*x.^2.*t_mat ...
        +gamma_2_plus.*x.*(x.*t_mat-f_bar).^(power-1).*((x.*t_mat-f_bar)>=0)).*exp(r_mat).*e_hat) ...
        .*normpdf(x,beta_f,sqrt(var_beta_f));
    scale_2 = quad_int(scale_2_fnc, [a], [b], n, 'legendre');
    q2_tilde_fnc = @(x) exp(-theta.*xi_d.*(gamma_1.*x ...
        +gamma_2.*x.^2.*t_mat ...
        +gamma_2_plus.*x.*(x.*t_mat-f_bar).^(power-1).*((x.*t_mat-f_bar)>=0)).*exp(r_mat).*e_hat)./scale_2;
    I_2 = -1./theta.*log(scale_2);
    J_2_without_e_fnc = @(x) xi_d.*exp(r_mat).*...
        q2_tilde_fnc(x) ...
        .*(gamma_1.*x +gamma_2.*t_mat.*x.^2 ...
        +gamma_2_plus.*x.*(x.*t_mat-f_bar).^(power-1).*((x.*t_mat-f_bar)>=0)) ...
        .*normpdf(x,beta_f,sqrt(var_beta_f));
    J_2_without_e = quad_int(J_2_without_e_fnc, [a], [b], n,'legendre');
    J_2_with_e = J_2_without_e.*e_hat;   
    R_2 = theta.*(I_2 - J_2_with_e);
    pi_tilde_2 = (1-weight).*exp(-theta.*I_2);
    pi_tilde_1_norm = pi_tilde_1./(pi_tilde_1+pi_tilde_2);
    pi_tilde_2_norm = 1-pi_tilde_1_norm;  

    expec_e_sum = (pi_tilde_1_norm.*(J_1_without_e) ...
        +pi_tilde_2_norm.*(J_2_without_e));
    B1 = v0_dr-v0_dt.*exp(r_mat)-expec_e_sum;  
    C1 = -delta.*alpha;
    e = -C1./B1;
    e_star = e; 
    
    J_1 = J_1_without_e.*e_star;
    J_2 = J_2_without_e.*e_star;
    I_term = -1./theta.*log(pi_tilde_1+pi_tilde_2);
    drift_distort = (pi_tilde_1_norm.*J_1 ...
        +pi_tilde_2_norm.*J_2);
    R_1 = theta.*(I_1 - J_1);
    R_2 = theta.*(I_2 - J_2);
    if (weight == 0 || weight == 1)
        RE = pi_tilde_1_norm.*R_1 + pi_tilde_2_norm.*R_2;
    else
        RE = pi_tilde_1_norm.*R_1 + pi_tilde_2_norm.*R_2 ...
            +pi_tilde_1_norm.*(log(pi_tilde_1_norm./weight)) ...
            +pi_tilde_2_norm.*(log(pi_tilde_2_norm./(1-weight)));        
    end
    RE_total = 1./theta.*RE;

    A = -delta.*ones(size(r_mat));
    B_r = -e_star+Gamma_r.*(f.^Theta_r).*exp(Theta_r.*(k_mat-r_mat))-0.5.*(sigma_r.^2);
    B_k = Alpha+Gamma.*log(1+i_k./Theta)-0.5.*(sigma_k.^2);
    B_t = e_star.*exp(r_mat);
    C_rr = 0.5.*sigma_r.^2.*ones(size(r_mat));
    C_kk = 0.5.*sigma_k.^2.*ones(size(r_mat));
    C_tt = zeros(size(r_mat));

    D = delta.*alpha.*log(e_star)+delta.*alpha.*r_mat ...
        + delta.*(1-alpha).*(log(A_O-i_k-f)+(k_mat)) ...
        + drift_distort + RE_total;   

    stateSpace = [r_mat(:), t_mat(:), k_mat(:)]; 
    model      = {};
    model.A    = A(:); 
    model.B    = [B_r(:), B_t(:), B_k(:)];
    model.C    = [C_rr(:), C_tt(:), C_kk(:)];
    model.D    = D(:);
    model.v0   = v0(:);
    model.dt   = dt;
    
    out = solveCGNatural(stateSpace, model);
    out_comp = reshape(out,size(v0)).*ones(size(r_mat));

    iter = iter+1;
    disp(['Diff: ', num2str(max(max(max(abs(out_comp - vold))))),' Number of Iters: ',num2str(iter)])

    v0 = v0.*ones(size(v0));
    v0 = reshape(out,size(v0));

    pde_error = A.*v0+B_r.*v0_dr+B_t.*v0_dt+B_k.*v0_dk+C_rr.*v0_drr+C_kk.*v0_dkk+C_tt.*v0_dtt+D;
    disp(['PDE Error: ', num2str(max(max(max(abs(pde_error)))))]) % check equation

    if (max(max(abs(out_comp - vold)))) < tol
        fprintf('PDE Converges');
    end

    toc
end

s0 = '/HJB_NonLinPref_Cumu';
filename = [pwd, s0];
save(filename); 

%% Step 3: The competitive problem;
close all
clear all
clc

load([pwd, '/climate_pars']);

r_min = 0;
r_max = 12; %r = logR
t_min = 0;
t_max = 4000;
k_min = 0;
k_max = 12; %k = logK
nr = 30;
nt = 40;
nk = 25;
r = linspace(r_min,r_max,nr)';
k = linspace(k_min,k_max,nk)';
hr = r(2) - r(1);
hk = k(2) - k(1);

dt = 0.5;
tol = 1e-16;

[r_mat,k_mat] = ndgrid(r,k); 

v0 = (alpha).*r_mat+(1-alpha).*k_mat; % initial guess
v1_initial = v0.*ones(size(r_mat));
out = v0;
vold = v0 .* ones(size(v0));
iter = 1;

v0 = v0.*ones(size(v0));
v0 = reshape(out,size(v0));

v0_dr = zeros(size(v0));
v0_dr(2:end-1,:) = (1./(2.*hr)).*(v0(3:end,:)-v0(1:end-2,:));
v0_dr(end,:) = (1./hr).*(v0(end,:)-v0(end-1,:));
v0_dr(1,:) = (1./hr).*(v0(2,:)-v0(1,:));
v0_dr(v0_dr<1e-8) = 1e-8;

v0_dk = zeros(size(v0));
v0_dk(:,2:end-1) = (1./(2.*hk)).*(v0(:,3:end)-v0(:,1:end-2));
v0_dk(:,end) = (1./hk).*(v0(:,end)-v0(:,end-1));
v0_dk(:,1) = (1./hk).*(v0(:,2)-v0(:,1));

v0_drr = zeros(size(v0));
v0_drr(2:end-1,:) = (1./(hr.^2)).*(v0(3:end,:)+v0(1:end-2,:)-2.*v0(2:end-1,:));
v0_drr(end,:) = (1./(hr.^2)).*(v0(end,:)+v0(end-2,:)-2.*v0(end-1,:));
v0_drr(1,:) = (1./(hr.^2)).*(v0(3,:)+v0(1,:)-2.*v0(2,:));

v0_dkk = zeros(size(v0));
v0_dkk(:,2:end-1) = (1./(hk.^2)).*(v0(:,3:end)+v0(:,1:end-2)-2.*v0(:,2:end-1));
v0_dkk(:,end) = (1./(hk.^2)).*(v0(:,end)+v0(:,end-2)-2.*v0(:,end-1));
v0_dkk(:,1) = (1./(hk.^2)).*(v0(:,3)+v0(:,1)-2.*v0(:,2));

%FOC
e = delta.*alpha./v0_dr;
Acoeff = ones(size(r_mat));
Bcoeff = ((delta.*(1-alpha)./Theta+Gamma./Theta.*v0_dk).*delta.*(1-alpha)./(v0_dr.*Gamma_r.*0.5)...
    .*exp(0.5.*(r_mat-k_mat)))./(delta.*(1-alpha)./Theta);
Ccoeff = -A_O - Theta;
f = ((-Bcoeff+sqrt(Bcoeff.^2 - 4.*Acoeff.*Ccoeff))./(2.*Acoeff)).^(2);
i_k = A_O-f-(delta.*(1-alpha))./(v0_dr.*Gamma_r.*0.5).*f.^0.5.*exp(0.5.*(r_mat-k_mat));

A = -delta.*ones(size(r_mat));
B_r = -e+Gamma_r.*(f.^Theta_r).*exp(Theta_r.*(k_mat-r_mat))-0.5.*(sigma_r.^2);
B_k = Alpha+Gamma.*log(1+i_k./Theta)-0.5.*(sigma_k.^2);
C_rr = 0.5.*sigma_r.^2.*ones(size(r_mat));
C_kk = 0.5.*sigma_k.^2.*ones(size(r_mat));

D = delta.*alpha.*log(e)+delta.*alpha.*r_mat ...
    + delta.*(1-alpha).*(log(A_O-i_k-f)+(k_mat));    

stateSpace = [r_mat(:), k_mat(:)]; 
model      = {};
model.A    = A(:); 
model.B    = [B_r(:), B_k(:)];
model.C    = [C_rr(:), C_kk(:)];
model.D    = D(:);
model.v0   = v0(:);
model.dt   = dt;

out = solveCGNatural(stateSpace, model);
out_comp = reshape(out,size(v0)).*ones(size(r_mat));
    
disp(['Error: ', num2str(max(max(max(abs(out_comp - v1_initial)))))])
v0 = v0.*ones(size(v0));
v0 = reshape(out,size(v0));

while (max(max(max(abs(out_comp - vold))))) > tol 
   tic
   vold = v0 .* ones(size(v0));
   
    v0_dr = zeros(size(v0));
    v0_dr(2:end-1,:) = (1./(2.*hr)).*(v0(3:end,:)-v0(1:end-2,:));
    v0_dr(end,:) = (1./hr).*(v0(end,:)-v0(end-1,:));
    v0_dr(1,:) = (1./hr).*(v0(2,:)-v0(1,:));
    v0_dr(v0_dr<1e-8) = 1e-8;

    v0_dk = zeros(size(v0));
    v0_dk(:,2:end-1) = (1./(2.*hk)).*(v0(:,3:end)-v0(:,1:end-2));
    v0_dk(:,end) = (1./hk).*(v0(:,end)-v0(:,end-1));
    v0_dk(:,1) = (1./hk).*(v0(:,2)-v0(:,1));

    v0_drr = zeros(size(v0));
    v0_drr(2:end-1,:) = (1./(hr.^2)).*(v0(3:end,:)+v0(1:end-2,:)-2.*v0(2:end-1,:));
    v0_drr(end,:) = (1./(hr.^2)).*(v0(end,:)+v0(end-2,:)-2.*v0(end-1,:));
    v0_drr(1,:) = (1./(hr.^2)).*(v0(3,:)+v0(1,:)-2.*v0(2,:));

    v0_dkk = zeros(size(v0));
    v0_dkk(:,2:end-1) = (1./(hk.^2)).*(v0(:,3:end)+v0(:,1:end-2)-2.*v0(:,2:end-1));
    v0_dkk(:,end) = (1./(hk.^2)).*(v0(:,end)+v0(:,end-2)-2.*v0(:,end-1));
    v0_dkk(:,1) = (1./(hk.^2)).*(v0(:,3)+v0(:,1)-2.*v0(:,2));



    e = delta.*alpha./v0_dr;
    f = ((delta.*(1-alpha)./Theta.*A_O-f.*delta.*(1-alpha)./Theta+delta.*(1-alpha)) ...
       ./(exp(Theta_r.*(r_mat-k_mat)).*(delta.*(1-alpha)./Theta+Gamma./Theta.*v0_dk).*delta.*(1-alpha)./(v0_dr.*Theta_r.*Gamma_r))) ...
       .^(1./(1-Theta_r));    
    f = f.*(v0_dr>1e-8);
    i_k = (A_O-f-(delta.*(1-alpha))./(v0_dr.*Gamma_r.*Theta_r).*f.^(1-Theta_r).*exp(Theta_r.*(r_mat-k_mat))).*(v0_dr>1e-8)...
        + (v0_dr<=1e-8).*(v0_dk.*Gamma.*A_O - delta.*(1-alpha).*Theta)./(delta.*(1-alpha)+v0_dk.*Gamma);

    A = -delta.*ones(size(r_mat));
    B_r = -e+Gamma_r.*(f.^Theta_r).*exp(Theta_r.*(k_mat-r_mat))-0.5.*(sigma_r.^2);
    B_k = Alpha+Gamma.*log(1+i_k./Theta)-0.5.*(sigma_k.^2);
    C_rr = 0.5.*sigma_r.^2.*ones(size(r_mat));
    C_kk = 0.5.*sigma_k.^2.*ones(size(r_mat));
  
    D = delta.*alpha.*log(e)+delta.*alpha.*r_mat ...
        + delta.*(1-alpha).*(log(A_O-i_k-f)+(k_mat));   

    stateSpace = [r_mat(:), k_mat(:)]; 
    model      = {};
    model.A    = A(:); 
    model.B    = [B_r(:), B_k(:)];
    model.C    = [C_rr(:), C_kk(:)];
    model.D    = D(:);
    model.v0   = v0(:);
    model.dt   = dt;

    out = solveCGNatural(stateSpace, model);
    out_comp = reshape(out,size(v0)).*ones(size(r_mat));

    iter = iter+1;
    disp(['Diff: ', num2str(max(max(max(abs(out_comp - vold))))),' Number of Iters: ',num2str(iter)])

    v0 = v0.*ones(size(v0));
    v0 = reshape(out,size(v0));

    pde_error = A.*v0+B_r.*v0_dr+B_k.*v0_dk+C_rr.*v0_drr+C_kk.*v0_dkk+D;
    disp(['PDE Error: ', num2str(max(max(max(abs(pde_error)))))])
    
    if (max(max(abs(out_comp - vold)))) < tol
        fprintf('PDE Converges');
    end

    toc
end

s0 = '/HJB_Comp';
filename = [pwd, s0];
save(filename);
%% Step 4: Simulation

clear all
close all
clc

filename1 = [pwd,'/HJB_Comp'];
load(filename1);
filename2 = [pwd,'/HJB_Comp'];
filename3 = [filename2,'_Sims'];

T = 100; % 100 years
pers = 4*T; % quarterly
dt = T/pers;
nDims = 3;
its = 1;

efunc = griddedInterpolant(r_mat,k_mat,e,'spline');
i_kfunc = griddedInterpolant(r_mat,k_mat,i_k,'spline');
ffunc = griddedInterpolant(r_mat,k_mat,f,'spline');

e_func = @(x) efunc(log(x(:,1)),log(x(:,2)));
i_k_func = @(x) i_kfunc(log(x(:,1)),log(x(:,2)));
f_func = @(x) max(ffunc(log(x(:,1)),log(x(:,2))),0);

file1 = [pwd, '/HJB_NonLinPref_Cumu'];
Model1 = load(file1,'t_min','t_max'); 
t_max = Model1.t_max;
t_min = Model1.t_min;

% initial points
R_0 = 650;
K_0 = 80/A_O;
T_0 = (870-580);

% function handles
muR = @(x) -e_func(x)+Gamma_r.*(f_func(x).*x(:,2)./x(:,1)).^Theta_r;
muK = @(x) (Alpha + Gamma.*log(1+i_k_func(x)./Theta));
muT = @(x) e_func(x).*x(:,1);

sigmaR = @(x) [zeros(size(x(:,1:3)))];
sigmaK = @(x) [zeros(size(x(:,1:3)))];
sigmaT = @(x) [zeros(size(x(:,1:3)))];

% set bounds
R_max = exp(r_max);
K_max = exp(k_max);
T_max = t_max;

R_min = exp(r_min);
K_min = exp(k_min);
T_min = t_min;

upperBounds = [R_max,K_max,T_max];
lowerBounds = [R_min,K_min,T_min];

hists = zeros(pers,nDims,its);
hists2 = hists;
e_hists = zeros(pers,its);
e_hists2 = e_hists;
f_hists = zeros(pers,its);
f_hists2 = f_hists;
i_k_hists = zeros(pers,its);
i_k_hists2 = i_k_hists;

for iters = 1:its
    
hist2 = zeros(pers,nDims);
e_hist2 = zeros(pers,1);
i_k_hist2 = zeros(pers,1);
f_hist2 = zeros(pers,1);


hist2(1,:) = [R_0,K_0,T_0];
e_hist2(1) =  e_func(hist2(1,:)).*hist2(1,1);
i_k_hist2(1) =  i_k_func(hist2(1,:)).*hist2(1,2);
f_hist2(1) =  f_func(hist2(1,:)).*hist2(1,2);

for j = 2:pers
shock = normrnd(0,sqrt(dt), 1, nDims);
hist2(j,1) = max(min(hist2(j-1,1).*exp((muR(hist2(j-1,:))-0.5.*sum((sigmaR(hist2(j-1,:))).^2) )* dt ...
                                  +sigmaR(hist2(j-1,:))* shock'), upperBounds(:,1)), lowerBounds(:,1));
hist2(j,2) = max(min(hist2(j-1,2).*exp((muK(hist2(j-1,:))-0.5.*sum((sigmaK(hist2(j-1,:))).^2) )* dt ...
                                  +sigmaK(hist2(j-1,:))* shock'), upperBounds(:,2)), lowerBounds(:,2));                              
hist2(j,3) = max(min(hist2(j-1,3) + muT(hist2(j-1,:)) * dt + sigmaT(hist2(j-1,:))* shock', upperBounds(:,3)), lowerBounds(:,3)); 

e_hist2(j) = e_func(hist2(j-1,:)).*hist2(j-1,1);
i_k_hist2(j) = i_k_func(hist2(j-1,:)).*hist2(j-1,2);
f_hist2(j) =  f_func(hist2(j-1,:)).*hist2(j-1,2);

end

hists2(:,:,iters) = hist2;
e_hists2(:,iters) = e_hist2;
i_k_hists2(:,iters) = i_k_hist2;
f_hists2(:,iters) = f_hist2; 

end

% save results
save(filename3);
e_values = mean(e_hists2,2);
s_e = strcat('e_comp.mat');
save(s_e,'e_values');

%% Step 5: SCC calculation
close all
clear all
clc

load([pwd, '/HJB_NonLinPref_Cumu']);

base_model_flow_func = @(x) ...
    (gamma_2.*x.^2 +bar_gamma_2_plus.*x.^2.*((x.*t_mat-f_bar)>=0)).*exp(r_mat).*e...
    .*normpdf(x,beta_f,sqrt(var_beta_f)); 
base_model_flow = quad_int(base_model_flow_func, a, b, n,'legendre');
flow_base = base_model_flow;

A = -delta.*ones(size(r_mat));
B_r = -e+Gamma_r.*(f.^Theta_r).*exp(Theta_r.*(k_mat-r_mat))-0.5.*(sigma_r.^2);
B_k = Alpha+Gamma.*log(1+i_k./Theta)-0.5.*(sigma_k.^2);
B_t = e.*exp(r_mat);
C_rr = 0.5.*sigma_r.^2.*ones(size(r_mat));
C_kk = 0.5.*sigma_k.^2.*ones(size(r_mat));
C_tt = zeros(size(r_mat));

D = flow_base;
            
stateSpace = [r_mat(:), t_mat(:), k_mat(:)]; 
model      = {};
model.A    = A(:); 
model.B    = [B_r(:), B_t(:), B_k(:)];
model.C    = [C_rr(:), C_tt(:), C_kk(:)];
model.D    = D(:);
model.v0   = v0(:).*0;
model.dt   = 1.0;
    
out = solveCGNatural_1(stateSpace, model);

% save results
v0 = reshape(out,size(r_mat));
filename2 = [pwd, '/SCC_mat_Cumu_base'];
save(filename2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all
clc

load([pwd, '/HJB_NonLinPref_Cumu']);

mean_nordhaus = beta_tilde_1;
lambda_tilde_nordhaus = lambda_tilde_1;

scale_2_1_fnc = @(x) exp(-theta.*xi_d.*(gamma_1.*x ...
    +gamma_2.*x.^2.*t_mat ...
    +gamma_2_plus.*x.*(x.*t_mat-f_bar).^(power-1).*((x.*t_mat-f_bar)>=0)).*exp(r_mat).*e) ...
    .*normpdf(x,beta_f,sqrt(var_beta_f));
scale_2_1 = quad_int(scale_2_1_fnc, [a], [b], n, 'legendre');

q2_tilde_1_fnc = @(x) exp(-theta.*xi_d.*(gamma_1.*x ...
    +gamma_2.*x.^2.*t_mat ...
    +gamma_2_plus.*x.*(x.*t_mat-f_bar).^(power-1).*((x.*t_mat-f_bar)>=0)).*exp(r_mat).*e)./scale_2_1;

nordhaus_model_flow = (gamma_2.*(1./lambda_tilde_nordhaus+mean_nordhaus.^2)).*exp(r_mat).*e;
weitzman_model_flow_func = @(x) q2_tilde_1_fnc(x) ...
    .*(gamma_2.*x.^2 +gamma_2_plus.*x.^2.*((x.*t_mat-f_bar)>=0)).*exp(r_mat).*e ...
    .*normpdf(x,beta_f,sqrt(var_beta_f));
weitzman_model_flow = quad_int(weitzman_model_flow_func, [a], [b], n, 'legendre');

I_1 = -0.5.*log(lambda)./theta + 0.5.*log(lambda_tilde_1)./theta ...
    +0.5.*lambda.*beta_f.^2./theta -0.5.*lambda_tilde_1.*(beta_tilde_1).^2./theta;
pi_tilde_1 = weight.*exp(-theta.*I_1);  
I_2 = -1./theta.*log(scale_2_1);
pi_tilde_2 = (1-weight).*exp(-theta.*I_2);
pi_tilde_1_norm = pi_tilde_1./(pi_tilde_1+pi_tilde_2);
pi_tilde_2_norm = 1-pi_tilde_1_norm;

flow_tilted = pi_tilde_1_norm.*nordhaus_model_flow ...
    +(1-pi_tilde_1_norm).*weitzman_model_flow;

A = -delta.*ones(size(r_mat));
B_r = -e+Gamma_r.*(f.^Theta_r).*exp(Theta_r.*(k_mat-r_mat))-0.5.*(sigma_r.^2);
B_k = Alpha+Gamma.*log(1+i_k./Theta)-0.5.*(sigma_k.^2);
B_t = e.*exp(r_mat);
C_rr = 0.5.*sigma_r.^2.*ones(size(r_mat));
C_kk = 0.5.*sigma_k.^2.*ones(size(r_mat));
C_tt = zeros(size(r_mat));

D = flow_tilted;

stateSpace = [r_mat(:), t_mat(:), k_mat(:)]; 
model      = {};
model.A    = A(:); 
model.B    = [B_r(:), B_t(:), B_k(:)];
model.C    = [C_rr(:), C_tt(:), C_kk(:)];
model.D    = D(:);
model.v0   = v0(:).*0;
model.dt   = 1.0;

out = solveCGNatural_1(stateSpace, model);

v0 = reshape(out,size(r_mat));
filename2 = [pwd, '/SCC_mat_Cumu_worst'];
save(filename2)

%%% SCC calculation
close all;
clear all;
clc;

% load results
file2 = [pwd, '/SCC_mat_Cumu_base'];
Model2 = load(file2,'v0','r_mat','k_mat','t_mat','i_k','f','e','v0_dk','v0_dr','theta',...
    'A_O','alpha','delta','Theta','Gamma','expec_e_sum','xi_d','a','b','n','gamma_1','gamma_2','f_bar',...
    'bar_gamma_2_plus','beta_f','var_beta_f','power');
external_v0 = Model2.v0;
r_mat = Model2.r_mat;
k_mat = Model2.k_mat;
t_mat = Model2.t_mat;
gamma_1 = Model2.gamma_1;
gamma_2 = Model2.gamma_2;
f_bar = Model2.f_bar;
theta = Model2.theta;
A_O = Model2.A_O;
alpha = Model2.alpha;
delta = Model2.delta;
Gamma = Model2.Gamma;
Theta = Model2.Theta;
xi_d = Model2.xi_d;
a = Model2.a;
b = Model2.b;
n = Model2.n;
bar_gamma_2_plus = Model2.bar_gamma_2_plus;
beta_f = Model2.beta_f;
var_beta_f = Model2.var_beta_f;
power = Model2.power;

file1 = [pwd,'/HJB_NonLinPref_Cumu'];
Model1 = load(file1,'v0_dr','v0_dk','v0_dt','i_k','f','e','expec_e_sum');
v0_dk = Model1.v0_dk;
v0_dr = Model1.v0_dr;
v0_dt = Model1.v0_dt;
i_k = Model1.i_k;
f = Model1.f;
e = Model1.e;
expec_e_sum = Model1.expec_e_sum;

MC = delta.*(1-alpha)./(A_O.*exp(k_mat)-i_k.*exp(k_mat)-f.*exp(k_mat));
ME = delta.*alpha./(e.*exp(r_mat));
SCC = 1000*ME./MC;
SCC_func = griddedInterpolant(r_mat,t_mat,k_mat,SCC,'spline');

ME1 = (v0_dr.*exp(-r_mat));  
SCC1 = 1000*ME1./MC;
SCC1_func = griddedInterpolant(r_mat,t_mat,k_mat,SCC1,'linear');

ME2_base =  (1-alpha).*external_v0;
SCC2_base = 1000*ME2_base./MC;
SCC2_base_func = griddedInterpolant(r_mat,t_mat,k_mat,SCC2_base,'spline');

V_d_baseline_func = @(x) xi_d...
         .*(gamma_1.*x +gamma_2.*t_mat.*x.^2 ...
        +bar_gamma_2_plus.*x.*(x.*t_mat-f_bar).^(power-1).*((x.*t_mat-f_bar)>=0)) ...
        .*normpdf(x,beta_f,sqrt(var_beta_f));
V_d_baseline = quad_int(V_d_baseline_func, [a], [b], n,'legendre');

ME2b = - V_d_baseline;
SCC2_V_d_baseline = 1000*ME2b./MC;
SCC2_V_d_baseline_func = griddedInterpolant(r_mat,t_mat,k_mat,SCC2_V_d_baseline,'spline');

file2 = [pwd, '/SCC_mat_Cumu_worst'];
Model2 = load(file2,'v0','r_mat','k_mat','t_mat');
external_v0_worst = Model2.v0;
r_mat = Model2.r_mat;
k_mat = Model2.k_mat;
t_mat = Model2.t_mat;

ME2_tilt =  (1-alpha).*external_v0_worst;
SCC2_tilt = 1000*ME2_tilt./MC;
SCC2_tilt_func = griddedInterpolant(r_mat,t_mat,k_mat,SCC2_tilt,'spline');

ME2b = - expec_e_sum.*exp(-r_mat);
SCC2_V_d_tilt = 1000*ME2b./MC;
SCC2_V_d_tilt_func = griddedInterpolant(r_mat,t_mat,k_mat,SCC2_V_d_tilt,'spline');

file1 = [pwd, '/HJB_Comp_Sims'];
Model1 = load(file1,'hists2');
hists2_A = Model1.hists2;

% calculate SCC
for time=1:400
    for path=1:1
    SCC_values(time,path) = SCC_func(log((hists2_A(time,1,path))),(hists2_A(time,3,path)),log((hists2_A(time,2,path))));
    SCC1_values(time,path) = SCC1_func(log((hists2_A(time,1,path))),(hists2_A(time,3,path)),log((hists2_A(time,2,path))));
    SCC2_base_values(time,path) = SCC2_base_func(log((hists2_A(time,1,path))),(hists2_A(time,3,path)),log((hists2_A(time,2,path))));
    SCC2_tilt_values(time,path) = SCC2_tilt_func(log((hists2_A(time,1,path))),(hists2_A(time,3,path)),log((hists2_A(time,2,path))));
    SCC2_V_d_baseline_values(time,path) = SCC2_V_d_baseline_func(log((hists2_A(time,1,path))),(hists2_A(time,3,path)),log((hists2_A(time,2,path))));
    SCC2_V_d_tilt_values(time,path) = SCC2_V_d_tilt_func(log((hists2_A(time,1,path))),(hists2_A(time,3,path)),log((hists2_A(time,2,path))));
    
    end
end

SCC_total = mean(SCC_values,2);
SCC_private = mean(SCC1_values,2);
SCC2_FK_base = mean(SCC2_base_values,2);
SCC2_FK_tilt = mean(SCC2_tilt_values,2);
SCC2_V_d_baseline = mean(SCC2_V_d_baseline_values,2);
SCC2_V_d_tilt = mean(SCC2_V_d_tilt_values,2);

SCC = SCC_total;
SCC1 = SCC_private;
SCC2 = SCC2_FK_base+SCC2_V_d_baseline;
SCC3 = SCC2_V_d_tilt-SCC2_V_d_baseline...
    +SCC2_FK_tilt-SCC2_FK_base;

% save results
s_scc = strcat('SCC_comp.mat');
save(s_scc,'SCC','SCC1','SCC2','SCC3');
