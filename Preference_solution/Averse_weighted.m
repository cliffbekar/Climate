%%%%% This file generates results for the Ambiguity Averse, Weighted Damage model.
% Authors: Mike Barnett, Jieyao Wang
% Last update: Dec 9, 2019
close all
clear all
clc

%% Step 0: set up solver
mex solveCGNatural.cpp;

%% Step 1: Set up parameters

McD = csvread('TCRE_MacDougallEtAl2017_update.csv');
McD = McD./1000;
par_lambda_McD = McD(:,1);
beta_f = mean(par_lambda_McD); 
var_beta_f = var(par_lambda_McD);
lambda = 1./var_beta_f;
delta = 0.01;
kappa= 0.032;
sigma_g = 0.02;
sigma_k = 0.0161;
sigma_r = 0.0339;
alpha = 0.115000000000000;
phi_0 = 0.0600;
phi_1 = 16.666666666666668;
mu_k = -0.034977443912449;
psi_0 = 0.112733407891680;
psi_1 = 0.142857142857143;
power = 2;
gamma_1 =  0.00017675;
gamma_2 =  2.*0.0022;
gamma_2_plus = 2.*0.0197;
sigma_1 = 0;
sigma_2 = 0;
rho_12 = 0;
gamma_bar = 2;
crit = 2;
F0 = 1;
sigma = [sigma_1.^2, rho_12; rho_12, sigma_2.^2];
Sigma = [var_beta_f,0,0;0,sigma_1.^2, rho_12; 0, rho_12, sigma_2.^2];
dee = [gamma_1 + gamma_2.*F0+gamma_2_plus.*(F0-gamma_bar).^2.*(F0>=2),beta_f,beta_f.*F0];
sigma_d = sqrt(dee*Sigma*dee');
xi_d = -1.*(1-kappa);

weight = 0.5; % weight on nordhaus
bar_gamma_2_plus = weight.*0+(1-weight).*gamma_2_plus;

xi_p = 1 ./ 4000; % ambiguity parameter

%% Step 2: solve HJB
r_min = 0;
r_max = 9; %r = logR
F_min = 0;
F_max = 4000;
k_min = 0;
k_max = 18; %k = logK

hr = 0.05;
ht = 25;
hk = 0.15;

r = r_min:hr:r_max;
t = F_min:ht:F_max;
k = k_min:hk:k_max;
[r_mat,F_mat,k_mat] = ndgrid(r,t,k); 

quadrature = 'legendre';
n = 30;
a = beta_f-5.*sqrt(var_beta_f);
b = beta_f+5.*sqrt(var_beta_f);

tol = 1e-8; % tol
dt = 0.3 % epsilon
v0 = (kappa).*r_mat+(1-kappa).*k_mat-beta_f.*F_mat; % initial guess
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
v0_dr(v0_dr<1e-16) = 1e-16;

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
B1 = v0_dr-xi_d.*(gamma_1(1)+gamma_2(1)*(F_mat).*beta_f+gamma_2_plus(1).*(F_mat.*beta_f-gamma_bar).^(power-1).*(F_mat>=(crit./beta_f))) ...
    .*beta_f.*exp(r_mat)-v0_dt.*exp(r_mat);  
C1 = -delta.*kappa;
e = -C1./B1;
e_hat = e;

Acoeff = ones(size(r_mat));
Bcoeff = ((delta.*(1-kappa).*phi_1+phi_0.*phi_1.*v0_dk).*delta.*(1-kappa)./(v0_dr.*psi_0.*0.5)...
    .*exp(0.5.*(r_mat-k_mat)))./(delta.*(1-kappa).*phi_1);
Ccoeff = -alpha - 1./phi_1;
j = ((-Bcoeff+sqrt(Bcoeff.^2 - 4.*Acoeff.*Ccoeff))./(2.*Acoeff)).^(2);
i_k = alpha-j-(delta.*(1-kappa))./(v0_dr.*psi_0.*0.5).*j.^0.5.*exp(0.5.*(r_mat-k_mat));

% update prob.
a_1 = zeros(size(r_mat));
b_1 = xi_d.*e_hat.*exp(r_mat).*gamma_1;
c_1 = 2.*xi_d.*e_hat.*exp(r_mat).*F_mat.*gamma_2;
lambda_tilde_1 = lambda+c_1./xi_p;
beta_tilde_1 = beta_f-c_1./xi_p./lambda_tilde_1.*beta_f-1./xi_p./lambda_tilde_1.*b_1;
I_1 = a_1-0.5.*log(lambda).*xi_p + 0.5.*log(lambda_tilde_1).*xi_p ...
    +0.5.*lambda.*beta_f.^2.*xi_p -0.5.*lambda_tilde_1.*(beta_tilde_1).^2.*xi_p;
J_1_without_e = xi_d.*(gamma_1.*beta_tilde_1 ...
    +gamma_2.*F_mat.*(beta_tilde_1.^2+1./lambda_tilde_1)).*exp(r_mat) ;
pi_tilde_1 = weight.*exp(-1./xi_p.*I_1);

scale_2_fnc = @(x) exp(-1./xi_p.*xi_d.*(gamma_1.*x ...
    +gamma_2.*x.^2.*F_mat ...
    +gamma_2_plus.*x.*(x.*F_mat-gamma_bar).^(power-1).*((x.*F_mat-gamma_bar)>=0)).*exp(r_mat).*e_hat) ...
    .*normpdf(x,beta_f,sqrt(var_beta_f));
scale_2 = quad_int(scale_2_fnc, [a], [b], n, 'legendre'); % quadrature
q2_tilde_fnc = @(x) exp(-1./xi_p.*xi_d.*(gamma_1.*x ...
    +gamma_2.*x.^2.*F_mat ...
    +gamma_2_plus.*x.*(x.*F_mat-gamma_bar).^(power-1).*((x.*F_mat-gamma_bar)>=0)).*exp(r_mat).*e_hat)./scale_2;
I_2 = -1.*xi_p.*log(scale_2);
J_2_without_e_fnc = @(x) xi_d.*exp(r_mat).*...
    q2_tilde_fnc(x) ...
    .*(gamma_1.*x +gamma_2.*F_mat.*x.^2 ...
    +gamma_2_plus.*x.*(x.*F_mat-gamma_bar).^(power-1).*((x.*F_mat-gamma_bar)>=0)) ...
    .*normpdf(x,beta_f,sqrt(var_beta_f));
J_2_without_e = quad_int(J_2_without_e_fnc, [a], [b], n,'legendre'); % quadrature
J_2_with_e = J_2_without_e.*e_hat;
pi_tilde_2 = (1-weight).*exp(-1./xi_p.*I_2);
pi_tilde_1_norm = pi_tilde_1./(pi_tilde_1+pi_tilde_2);
pi_tilde_2_norm = 1-pi_tilde_1_norm;  
    
expec_e_sum = (pi_tilde_1_norm.*(J_1_without_e) ...
    +pi_tilde_2_norm.*(J_2_without_e));
B1 = v0_dr-v0_dt.*exp(r_mat)-expec_e_sum;  
C1 = -delta.*kappa;
e = -C1./B1; % FOC 
e_star = e; 

J_1 = J_1_without_e.*e_star;
J_2 = J_2_without_e.*e_star;
I_term = -1.*xi_p.*log(pi_tilde_1+pi_tilde_2);
R_1 = 1./xi_p.*(I_1 - J_1);     
R_2 = 1./xi_p.*(I_2 - J_2);
drift_distort = (pi_tilde_1_norm.*J_1 ...
    +pi_tilde_2_norm.*J_2);   
if (weight == 0 || weight == 1)
    RE = pi_tilde_1_norm.*R_1 + pi_tilde_2_norm.*R_2;
else
    RE = pi_tilde_1_norm.*R_1 + pi_tilde_2_norm.*R_2 ...
        +pi_tilde_1_norm.*(log(pi_tilde_1_norm./weight)) ...
        +pi_tilde_2_norm.*(log(pi_tilde_2_norm./(1-weight)));        
end
RE_total = 1.*xi_p.*RE;

% inputs for solver
A = -delta.*ones(size(r_mat));
B_r = -e_star+psi_0.*(j.^psi_1).*exp(psi_1.*(k_mat-r_mat))-0.5.*(sigma_r.^2);
B_k = mu_k+phi_0.*log(1+i_k.*phi_1)-0.5.*(sigma_k.^2);
B_t = e_star.*exp(r_mat);
C_rr = 0.5.*sigma_r.^2.*ones(size(r_mat));
C_kk = 0.5.*sigma_k.^2.*ones(size(r_mat));
C_tt = zeros(size(r_mat));

D = delta.*kappa.*log(e_star)+delta.*kappa.*r_mat ...
    + delta.*(1-kappa).*(log(alpha-i_k-j)+(k_mat)) ...
    + drift_distort + RE_total;    

stateSpace = [r_mat(:), F_mat(:), k_mat(:)]; 
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
q = delta.*(1-kappa)./(alpha-i_k-j);
% eta = 0.1;
eta = 0.05;
diff_pde_error = 1;
pde_error = A.*v0+B_r.*v0_dr+B_t.*v0_dt+B_k.*v0_dk+C_rr.*v0_drr+C_kk.*v0_dkk+C_tt.*v0_dtt+D;
rhs_err(iter) = max(max(max(abs(pde_error))));
lhs_error = max(max(max(abs(out_comp - v1_initial))));
lhs_err(iter) = lhs_error;

while lhs_error > tol % check for convergence
   tic
   vold = v0 .* ones(size(v0));
   
   if iter > 2000
       dt = 0.1;
   elseif iter > 1000
       dt = 0.2;
   end

    stateSpace = [r_mat(:), F_mat(:), k_mat(:)]; 
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

    if (mod(iter, 100) == 0)
        s0 = '/Averse_weighted_temp';
        filename = [pwd, s0];
        save(filename); % save HJB solution
    end 
    
    v0_dt = zeros(size(v0));
    v0_dt(:,2:end-1,:) = (1./(2.*ht)).*(v0(:,3:end,:)-v0(:,1:end-2,:));
    v0_dt(:,end,:) = (1./ht).*(v0(:,end,:)-v0(:,end-1,:));
    v0_dt(:,1,:) = (1./ht).*(v0(:,2,:)-v0(:,1,:));

    v0_dr = zeros(size(v0));
    v0_dr(2:end-1,:,:) = (1./(2.*hr)).*(v0(3:end,:,:)-v0(1:end-2,:,:));
    v0_dr(end,:,:) = (1./hr).*(v0(end,:,:)-v0(end-1,:,:));
    v0_dr(1,:,:) = (1./hr).*(v0(2,:,:)-v0(1,:,:));

    v0_dk = zeros(size(v0));
    v0_dk(:,:,2:end-1) = (1./(2.*hk)).*(v0(:,:,3:end)-v0(:,:,1:end-2));
    v0_dk(:,:,end) = (1./hk).*(v0(:,:,end)-v0(:,:,end-1));
    v0_dk(:,:,1) = (1./hk).*(v0(:,:,2)-v0(:,:,1));

    v0_drr = zeros(size(v0));
    v0_drr(2:end-1,:,:) = (1./(hr.^2)).*(v0(3:end,:,:)+v0(1:end-2,:,:)-2.*v0(2:end-1,:,:));
    v0_drr(end,:,:) = (1./(hr.^2)).*(v0(end,:,:)+v0(end-2,:,:)-2.*v0(end-1,:,:));
    v0_drr(1,:,:) = (1./(hr.^2)).*(v0(3,:,:)+v0(1,:,:)-2.*v0(2,:,:));
    
    v0_drr(v0_dr<1e-16) = 0;
    v0_dr(v0_dr<1e-16) = 1e-16;
    
    v0_dtt = zeros(size(v0));
    v0_dtt(:,2:end-1,:) = (1./(ht.^2)).*(v0(:,3:end,:)+v0(:,1:end-2,:)-2.*v0(:,2:end-1,:));
    v0_dtt(:,end,:) = (1./(ht.^2)).*(v0(:,end,:)+v0(:,end-2,:)-2.*v0(:,end-1,:));
    v0_dtt(:,1,:) = (1./(ht.^2)).*(v0(:,3,:)+v0(:,1,:)-2.*v0(:,2,:));

    v0_dkk = zeros(size(v0));
    v0_dkk(:,:,2:end-1) = (1./(hk.^2)).*(v0(:,:,3:end)+v0(:,:,1:end-2)-2.*v0(:,:,2:end-1));
    v0_dkk(:,:,end) = (1./(hk.^2)).*(v0(:,:,end)+v0(:,:,end-2)-2.*v0(:,:,end-1));
    v0_dkk(:,:,1) = (1./(hk.^2)).*(v0(:,:,3)+v0(:,:,1)-2.*v0(:,:,2));
    
    
    
    e_hat = e_star;
    
    q0 = q;
    i_k_0 = i_k;
    j_0 = j;

    Converged = 0;
    nums = 0;
    while Converged == 0
        istar = (phi_0.*phi_1.*v0_dk./q - 1)./phi_1;
        jstar = (q.*exp(psi_1.*(r_mat-k_mat))./((v0_dr).*psi_0.*psi_1)).^(1./(psi_1 - 1));
        if alpha > (istar+jstar)
            qstar = eta.*delta.*(1-kappa)./(alpha-istar-jstar)+(1-eta).*q;
        else
            qstar = 2.*q;
        end
        
        if (max(max(max(max(abs((qstar-q)./eta)))))<=1e-10)... && (max(max(max(max(abs(istar-i_k)))))<=1e-8)
            Converged = 1; 
        end
        
        q = qstar;
        i_k = istar;
        j = jstar;
        
        nums = nums+1;
    end

    a_1 = zeros(size(r_mat));
    b_1 = xi_d.*e_hat.*exp(r_mat).*gamma_1;
    c_1 = 2.*xi_d.*e_hat.*exp(r_mat).*F_mat.*gamma_2;
    lambda_tilde_1 = lambda+c_1./xi_p;
    beta_tilde_1 = beta_f-c_1./xi_p./lambda_tilde_1.*beta_f-1./xi_p./lambda_tilde_1.*b_1;
    I_1 = a_1-0.5.*log(lambda).*xi_p + 0.5.*log(lambda_tilde_1).*xi_p ...
        +0.5.*lambda.*beta_f.^2.*xi_p -0.5.*lambda_tilde_1.*(beta_tilde_1).^2.*xi_p;
    R_1 = 1./xi_p.*(I_1-(a_1+b_1.*beta_tilde_1+0.5.*c_1.*(beta_tilde_1).^2+0.5.*c_1./lambda_tilde_1));
    J_1_without_e = xi_d.*(gamma_1.*beta_tilde_1 ...
        +gamma_2.*F_mat.*(beta_tilde_1.^2+1./lambda_tilde_1)).*exp(r_mat) ;

    pi_tilde_1 = weight.*exp(-1./xi_p.*I_1);


    scale_2_fnc = @(x) exp(-1./xi_p.*xi_d.*(gamma_1.*x ...
        +gamma_2.*x.^2.*F_mat ...
        +gamma_2_plus.*x.*(x.*F_mat-gamma_bar).^(power-1).*((x.*F_mat-gamma_bar)>=0)).*exp(r_mat).*e_hat) ...
        .*normpdf(x,beta_f,sqrt(var_beta_f));
    scale_2 = quad_int(scale_2_fnc, [a], [b], n, 'legendre');
    q2_tilde_fnc = @(x) exp(-1./xi_p.*xi_d.*(gamma_1.*x ...
        +gamma_2.*x.^2.*F_mat ...
        +gamma_2_plus.*x.*(x.*F_mat-gamma_bar).^(power-1).*((x.*F_mat-gamma_bar)>=0)).*exp(r_mat).*e_hat)./scale_2;
    I_2 = -1.*xi_p.*log(scale_2);
    J_2_without_e_fnc = @(x) xi_d.*exp(r_mat).*...
        q2_tilde_fnc(x) ...
        .*(gamma_1.*x +gamma_2.*F_mat.*x.^2 ...
        +gamma_2_plus.*x.*(x.*F_mat-gamma_bar).^(power-1).*((x.*F_mat-gamma_bar)>=0)) ...
        .*normpdf(x,beta_f,sqrt(var_beta_f));
    J_2_without_e = quad_int(J_2_without_e_fnc, [a], [b], n,'legendre');
    J_2_with_e = J_2_without_e.*e_hat;   
    R_2 = 1./xi_p.*(I_2 - J_2_with_e);
    pi_tilde_2 = (1-weight).*exp(-1./xi_p.*I_2);
    pi_tilde_1_norm = pi_tilde_1./(pi_tilde_1+pi_tilde_2);
    pi_tilde_2_norm = 1-pi_tilde_1_norm;  

    expec_e_sum = (pi_tilde_1_norm.*(J_1_without_e) ...
        +pi_tilde_2_norm.*(J_2_without_e));
    B1 = v0_dr-v0_dt.*exp(r_mat)-expec_e_sum;  
    C1 = -delta.*kappa;
    e = -C1./B1;
    e_star = e; 
    
    J_1 = J_1_without_e.*e_star;
    J_2 = J_2_without_e.*e_star;
    I_term = -1.*xi_p.*log(pi_tilde_1+pi_tilde_2);
    drift_distort = (pi_tilde_1_norm.*J_1 ...
        +pi_tilde_2_norm.*J_2);
    R_1 = 1./xi_p.*(I_1 - J_1);
    R_2 = 1./xi_p.*(I_2 - J_2);
    if (weight == 0 || weight == 1)
        RE = pi_tilde_1_norm.*R_1 + pi_tilde_2_norm.*R_2;
    else
        RE = pi_tilde_1_norm.*R_1 + pi_tilde_2_norm.*R_2 ...
            +pi_tilde_1_norm.*(log(pi_tilde_1_norm./weight)) ...
            +pi_tilde_2_norm.*(log(pi_tilde_2_norm./(1-weight)));        
    end
    RE_total = 1.*xi_p.*RE;

    A = -delta.*ones(size(r_mat));
    B_r = -e_star+psi_0.*(j.^psi_1).*exp(psi_1.*(k_mat-r_mat))-0.5.*(sigma_r.^2);
    B_k = mu_k+phi_0.*log(1+i_k.*phi_1)-0.5.*(sigma_k.^2);
    B_t = e_star.*exp(r_mat);
    C_rr = 0.5.*sigma_r.^2.*ones(size(r_mat));
    C_kk = 0.5.*sigma_k.^2.*ones(size(r_mat));
    C_tt = zeros(size(r_mat));

    D = delta.*kappa.*log(e_star)+delta.*kappa.*r_mat ...
        + delta.*(1-kappa).*(log(alpha-i_k-j)+(k_mat)) ...
        + drift_distort + RE_total;   
    

    pde_error_new = A.*v0+B_r.*v0_dr+B_t.*v0_dt+B_k.*v0_dk+C_rr.*v0_drr+C_kk.*v0_dkk+C_tt.*v0_dtt+D;
    diff_pde_error = max(max(max(abs(pde_error_new - pde_error))));
    disp(['PDE Error: ', num2str(max(max(max(abs(pde_error)))))]) % check equation
    disp(['Change in pde error: ', num2str(diff_pde_error)]);
    pde_error = pde_error_new;
    
    rhs_err(iter) = max(max(max(abs(pde_error_new))));
    lhs_error = max(max(max(abs(out_comp - vold))));
    lhs_err(iter) = lhs_error;

    if lhs_error < tol
        fprintf('PDE Converges');
    end

    toc
end

s0 = '/Averse_weighted';
filename = [pwd, s0];
save(filename); % save HJB solution
stop;