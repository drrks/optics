%ESIM Simulates Basic Electrical Circuits

%read in netlist (basically)
%for large circuits we should pre-allocate .in .out and .mag matrices,
%but we won't be getting that large
clear variables;
timesteps = 10000; %this is embarrasingly arbitrary.
deltat=0.01; %same as above
nvoltage = input('Input number of voltage sources = ');

if nvoltage==0; vsource.in=[]; vsource.out=[]; end
for n=1:nvoltage
    fprintf('Voltage Source %g \n',n);
    vsource.in(n) = input('Input Node = ');
    vsource.out(n) = input('Output Node = ');
    vsource.mag(n) = input('Output Voltage = ');
end

nresist = input('Input number of resistors = ');
if nresist==0; resistor.in=[]; resistor.out=[]; end
for n=1:nresist
    fprintf('Resistor %g \n',n);
    resistor.in(n) = input('Input Node = ');
    resistor.out(n) = input('Output Node = ');
    resistor.mag(n) = input('Resistance = ');
end

ncap = input('Input number of capacitors = ');
if ncap==0; cap.in=[]; cap.out=[]; end
for n=1:ncap
    fprintf('Capacitor %g \n',n);
    cap.in(n) = input('Input Node = ');
    cap.out(n) = input('Output Node = ');
    cap.mag(n) = input('Capacitance = ');
end
%calculate number of nodesand branches (components)
nnodes = max([ max([vsource.out]) max([resistor.out]) max([cap.out]) ...
    max([vsource.in]) max([resistor.in]) max([cap.in]) ]); 

matsize= nnodes + size(vsource.mag,1);%plus buffer columns for sources

condmat = spalloc(matsize,matsize,2*size(resistor.in,2));
capmat = spalloc(matsize,matsize,2*size(cap.in,2));
source = zeros(matsize,1);
voltage = zeros(matsize,1);
%now we put all the components in their respective matrices
for n=1:nvoltage
    %for standard vector of voltage sources
    if vsource.in(n)~=0; 
        condmat(nnodes+n,vsource.in(n)) = -1;
    end
    if vsource.out(n)~=0; 
        condmat(nnodes+n,vsource.out(n)) = 1;
        condmat(vsource.out(n),nnodes+n) = 1;
    end
    source(nnodes+n)=vsource.mag(n);
    
    %     if vsource.out(n)~=0; source(vsource.out(n),1)=vsource.mag(n); end
    
end
for n=1:nresist
    if resistor.in(n)~=0;
        condmat(resistor.in(n),resistor.in(n))= condmat(resistor.in(n),resistor.in(n)) + 1/resistor.mag(n);
    end
    if resistor.out(n)~=0;
        condmat(resistor.out(n),resistor.out(n))=condmat(resistor.out(n),resistor.out(n)) + 1/resistor.mag(n);
    end
    if resistor.in(n)~=0 && resistor.out(n)~=0
        condmat(resistor.in(n),resistor.out(n)) = condmat(resistor.in(n),resistor.out(n)) - 1/resistor.mag(n);
        condmat(resistor.out(n),resistor.in(n))=condmat(resistor.out(n),resistor.in(n)) - 1/resistor.mag(n);       
    end
end
    for n=1:ncap
        if cap.in(n)~=0; 
            capmat(cap.in(n),cap.in(n))= capmat(cap.in(n),cap.in(n)) + cap.mag(n);
        end
        if cap.out(n)~=0; 
            capmat(cap.out(n),cap.out(n))= capmat(cap.out(n),cap.out(n)) + cap.mag(n);        
        end
        if cap.in(n)~=0 && cap.out(n)~=0;
           capmat(cap.in(n),cap.out(n)) = capmat(cap.in(n),cap.out(n)) - cap.mag(n);
           capmat(cap.out(n),cap.in(n)) = capmat(cap.out(n),cap.in(n)) - cap.mag(n);
            
        end
    end
    
    %time marching -- should have itcheck for convergence in solid-state system)
    for n=1:timesteps
        voltage(:,n+1)= ((capmat + deltat*condmat)\(capmat*voltage(:,n)+source*deltat));
        %for setting voltage in the voltage vector
        
        
    end
    figure;
    hold on
    for n=1:nnodes
        plot(voltage(n,:),n*deltat);
    end
    
    
