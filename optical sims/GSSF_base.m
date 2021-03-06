%GAFFE_DEMO_SOLITON Demonstrate soliton propagation.
%
%  This function demonstrates the propagation of a second order soliton in
%  

function GSSFbasev2(varargin)
global loss
S=0.02;
Options.MaxZ = input('Length in terms of L_D (minimum 3)= ');
loss = input('alpha, positive for loss, negative for gain = ');
%no loss yet, needs a tricky way to pass it to the dispersion function
S=input('Self Steepening Factor (0.02 default) = ');
chirp0 = 0; % input pulse chirp (default value) 

% Define default mesh type and error tolerance.
mesh='fibonacci&humble';
TolGlobal  = 1E-9;
TolAliased = 1E-16;

if nargin > 0
    mesh=varargin{1}; %change mesh type
end
if nargin > 1
  TolGlobal=varargin{2}; %change global tolerance
end
if nargin > 2
  TolAliased=varargin{3}; %change aliasing tolerance
end

% Initial number of samples, size of starting matrix for the wave (will be
% resized later)
N = round (100*Options.MaxZ); 
% Size of real space (multiples of pi)
W = 20*pi;

% Propagate a maximum of 1 
%Options.MaxZ =(2.5)*pi/2;

% Set mesh resizing to choice supplied by argument -- defaults.
Options.Callback.Mesh = evolvemeshset(mesh);
%defines an anonymous function to be called to evolve according to both
%kerr non-linearity and self-steepening.
SelfSteepeningAndKerr = @(dxi, omega, tau, u, fftu) ...
    DefaultSelfSteepening(S*dxi,omega,tau,u,fftu) .* ...
    DefaultKerr(dxi,[],[],u,[]);


%housekeeping stuff.
% Register this function handle as the nonlinear operator to use.
Options.Callback.OperatorNonlinear = SelfSteepeningAndKerr;

% Switch off any dispersion by using the identity linear operator.
Options.Callback.OperatorLinear = @DefaultDispersion;

% Execute plot_progress after each iteration.
Options.Callback.EndIteration = @plot_progress;

% Evolve the field.  This does the heavy lifting.
Options.TolAliased1=TolAliased;
Options.TolAliased2=TolAliased;
Options.TolGlobal=TolGlobal;
Options.MaxIterations=1E6;
N = Options.Callback.Mesh.SetInitialSize(N);


%creates base matrices for real and frequency space, step sizes
% Set up the space.
[tau,dtau,omega,domega]= fftspace(W,N);

% Generate the initial second order soliton pulse.
u0 = second_order_soliton(tau,0);
u0 = ifft(fft(u0));

% Run the simulation. passes to evolve function (down the rabbit hole we go)
[z,u1,tau1,omega1] = evolve(u0,tau,Options);

% Get internal values in plot_progress function. Checks error, and other
% values
[IsQuit, err] = plot_progress('get');
global waves;
% Finally report the maximum observed infinity norm error.
fprintf('Maximum error between analytical solution and numerical method is %d\n',max(err));

waves.u(:,~any(waves.u,1))=[];%truncate matrices
waves.z=waves.z(1:size(waves.u,2));
figure;
 meshz(waves.z,fftshift(waves.tau),fftshift(abs(waves.u),1))
 axis([0 Options.MaxZ -8 8 ])
view(-37.5,30);
end


%PLOT_PROGRESS A callback that plots progress.  Modelled in the same vain
%as DefaultEndIteration it updates a display of the solution, local and
%global errors.
function  [IsQuit, err] = plot_progress(varargin)

% This should always be set.
IsQuit = 0;

% Internal state variables.
persistent  dxi_ xi_  n_  N_ local_error_ iter_ err_ tlast tfirst;

% If we have passed parameters, then see what they are.
if nargin > 0
    switch lower(varargin{1})
        case 'set'
            throw(MException('SanityCheck:plot_progress','No internal variables to set'));
        case 'begin'
            % Called at the beginning of an iteration.
            n_ = 0;

            tic;
            tfirst = toc;
            tlast  = tfirst;
            dxi_   = zeros(100,1);
            xi_    = zeros(100,1);
            err_   = zeros(100,1);
            iter_  = zeros(100,1);
            N_     = zeros(100,1);
            local_error_ = zeros(100,1);
        case 'end'
            dxi_ = dxi_(1:n_); xi_ = xi_(1:n_); err_=err_(1:n_); 
            iter_=iter_(1:n_); N_ = N_(1:n_);   local_error_=local_error_(1:n_);
        case 'get'
            err = err_;
        otherwise
            throw(MException('SanityCheck:plot_progress','Argument to plot_progress should be ''get'', ''set'', ''begin'', ''end'' or nothing.'));
    end
    return
end

n_ = evalin('caller','n')+1;

% Get the position, step length and mesh size. 
xi_(n_)  = evalin('caller','z');
dxi_(n_) = evalin('caller','dz_try');
N_(n_)   = evalin('caller','size(u0,1)');

% Grab the current coordinate system and field.
t = fftshift(evalin('caller','x{1}'));
u = fftshift(evalin('caller','u1(:,1)'));

% Calculate local infinity norm error and get local fine / course solution
% error.
err_(n_) = max(abs(u - second_order_soliton(t,xi_(n_))));
local_error_(n_) = evalin('caller','local_error');

tnow=toc;
DT=tnow-tlast;
iter_(n_) = n_;

% Update the display every second.
% if DT >= 1 || xi_(n_) >= evalin('caller','o.MaxZ - dz - dz')
%     
%     % Update figure 1 with the current propagation step.
%     figure(1);
%     clf;
%     
%     % Soliton profile.
%     subplot(3,1,1);
%     plot(t,abs(u).^2,'.',t,abs(second_order_soliton(t,xi_(n_))).^2,'o-');
%     xlabel('t','FontSize',15); ylabel('Intensity','FontSize',15);
%     legend('u_{gaffe}','u_{analy}');
%     axis([-3 3 0 18]);
%     grid on;
%     
%     % Step size and mesh size.
%     subplot(3,1,2);
%     plotyy(2*xi_(1:n_)/pi,N_(1:n_),2*xi_(1:n_)/pi,dxi_(1:n_));
%     xlabel('z','FontSize',15);
%     legend('N','dz');
%     grid on;
%     
%     % Plot of local error and absolute error w.r.t. analytical soln.
%     subplot(3,1,3);
%     plotyy(iter_,local_error_,iter_,err_);
%     grid on;
%     xlabel('n','FontSize',15); 
%     legend('|epsilon_{local}|','|epsilon_{abs}|');
%     
%     
%     drawnow;
%     tlast=tnow;
% end

% Force the propagation engine to quit after 30 mins
if  abs(tnow-tfirst) > 60*30
    disp('Quitting since we have been going for over 30 minutes.');
    IsQuit=1;
end

end

% $Log: gaffe_demo_soliton.m,v $
% Revision 1.5  2010/05/24 12:38:16  graceej
% * Fixed yet another trivial bug with gaffe_demo_soliton.
%
% Revision 1.4  2010/05/24 12:22:33  graceej
% * Grabbing step size from wrong variable
%
% Revision 1.3  2010/05/24 08:23:52  graceej
% * Improved documentation.
% * Updated callback to follow the same as the DefaultEndIteration example.
%
% Revision 1.2  2010/05/22 21:42:47  graceej
% * Update with more reasonable display of progress.
%
% Revision 1.1  2010/05/22 20:57:59  graceej
% * Initial checkin of second order soliton demo.
%
