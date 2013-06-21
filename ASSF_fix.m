% This code solves the NLS equation with the split-step method
% idu/ dz - sgn(beta2) /2 d^2u/d(tau) ^2+N ^2*|u| ^2*|u| ^2u=0
% Written by Govind P. Agrawal in Marcg 2005 for the NLFO book
%---Specify imput parameters
clear variables;
distance = input('Enter fiber length (in units of L_D) = '); % entire legth, graphed at the end
beta2 = input('dispersion: 1 for normal, -1 for anomalous = '); % ?
N = input('Nonlinear parameter N = '); %Solition order?
mshape = input('m = 0 for sech, m > 0 for super-Gaussian = '); % decided on input wave
alpha = input('alpha, positive for loss, negative for gain = ');
ss = input('self steepening factor = ');
% y1=input('y1= ');
% y2=input('y2= ');
chirp0 = 0; % input pulse chirp (default value) ???????????????????????????????????????????????????
%---set simulation parameters
nt = 1024; Tmax = 32; % FFT points and window size for graphs
step_num = round (20 * distance * N^2); % No. of z steps
deltaz = distance/step_num; % step size in z
dtau = (2 * Tmax)/nt; % step size in tau (radians from z)
%---tau and omega arrays
timedomain = (-nt/2:nt/2-1) * dtau; % temporal grid
omega = (pi/Tmax) * [(0:nt/2-1) (-nt/2:-1)]; % frequency grid
%---Input Field profile
 % soliton sech shape creationg of input wave
    uu = sech(timedomain).* exp(-0.5i* chirp0* timedomain.^2);

    gtt=diag(-2*ones(nt,1),0) + diag(5*ones(nt-1,1),-1)  ...
        + diag(-4*ones(nt-2,1),-2) + diag(ones(nt-3,1),-3);
    gtt(1,nt)=5; gtt(1,nt-1)=-4; gtt(1,nt-2)=1;
    gtt(2,nt)=-4; gtt(2,nt-1)=1;
    gtt(3,nt)=1;
    gamma =zeros(nt); %% nonlinearality, and loss
   y=(gtt.*(-0.5i*beta2));
    
% ---plot inpute pulse shape and spectrum
%---Store dispersive phase shifts to speedup code
% dispersion = exp(0.5i*beta2*omega.^2*deltaz-0.5*alpha*deltaz); %phase factor, includes alpha
hhz= 1i*N^2 *deltaz; %nonlinear phase factor
%********[beginning of MAIN Loop] ********

% temp = uu.*exp(abs(uu).^2*hhz/2); % note hhz/2 first step, hhz (non-linear) decay
duu2_dt2=zeros(1,size(uu));
for n=0:step_num


    
%     duu_dt=ifft(1i.*omega.*temp);
%     duu_dt_star=ifft(1i.*omega.*fft(conj(temp)));
%     selfsteepen=exp((2.*conj(temp).*duu_dt + uu.*duu_dt_star).*deltaz.*ss);
    uu=uu*exp(y.*deltaz);
    du2_dt2=uu*gtt;
    subplot(2,1,1);
    plot(timedomain,abs(uu));
    title('Wave');
    subplot(2,1,2);
     plot(timedomain,du2_dt2);
    title('wave``');
    pause(0.01);

        
 
    %% to plot at every step
    %             hold on;
    %             subplot(2,1,1)
    %             plot(tau, abs(uu).^2, '-k')
    %             axis([-10 10 0 y1]);
    %             xlabel('Normalized Time');
    %             ylabel('Normalized Power');
    %             subplot(2,1,2)
    %             plot(fftshift(omega)/(2*pi), abs(tempplot).^2,'-k')
    %             axis([-2 2 0 y2]);
    %             xlabel('Normalized Frequency');
    %             ylabel('Spectral Power');
    %logs waveform over space

    wavespace(n+1,:)= abs(uu).^2;
    
end
figure;
wavespace(step_num+1,:)= abs(uu).^2;
mesh(deltaz.*timedomain,deltaz.*(0:step_num),deltaz.*wavespace)
view(37.5,30);
% axis([-10 10 0 distance 0 y1])
xlabel('T/T0');
ylabel('Z/Ld');
zlabel('Intesnsity');

