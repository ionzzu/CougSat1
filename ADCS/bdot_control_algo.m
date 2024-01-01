% bdot algorithm considering polar orbit as a simulation
% changes the frame of reference and adds the rotating matrix functions
% units MKS unless otherwise specified

clear all;
clc;

%% Specify time
dt = 0.32; % time step between data points
T = 90*60; % [s] orbital period of ISS [8]

t = 0:dt:T; % total time measurements
%% Initializations
inertia = [0.00602377522,0.00000294634,0.00000423169;0.00000294634,0.00130455071,0.00001311622;0.00000294634,0.00001311622,0.00601351576]';
% inertia [kg*m^2] is [Ixx,Ixy,Ixz; Iyx,Iyy,Iyz; Izx,Izy,Izz]

Ls = 400e3; % [m] satellite orbital altitude
alpha = zeros(length(t),3); % [rad/s^2] angular acceleration matrix
omega = zeros(length(t),3); % [rad/s] angular velocity matrix
theta = zeros(length(t),3); % [rad] satellite angle matrix
I = zeros(length(t),3); % [Amps] satellite current matrix
alpha_i = [0,0,0]; % [rad/s^2] instantaneous angular acceleration of satellite
omega_i = [1;-5;3]'; % [rad/s] instantaneous angular velocity of satellite
Re = 6371.2e3; % [m] Earth volumetric mean radius
Rs = Re+Ls; % [m] satellite distance from Earth
p = (111e3*Rs)/Re;
G = 6.67428e-11; % Earth gravitational constant
M = 5.9723e24; % [kg] Earth mass
v_sat = sqrt(G*M/Rs); % [m/s] linear velocity of satellite

for i = 1:length(t)
    omega_prev = omega_i; % [rad/s] previous angular velocity
    lati = (v_sat*i*dt)/p; % represents the polar orbit as latitude changes differently when its in space
    lat = 25+lati; % latitude changes due to the change in the y coordinate of the system
    long = 60+((7.29e-5*i*dt)*180/3.14159); % longitude changes as Earth is rotating
    % NOTE: actual latitude and longitude to be obtained from on-board GPS

    % Gives error on 90
    if lat > 90
        b = mod(lat,90);
        lat = 90-b;
    end
    if lat < -90
        c = mod(lat,-90);
        lat = -90-c;
    end
     if long > 180
        d = mod(long,180);
        long = d-180;
     end
    if long < -180
        l = mod(long,-180);
        long = 180+l;
    end
    if lat == 90
        lat = 89.97;
    end
    if lat == -90
        lat = -89.97;
    end

    [b_NRNC,horIntensity,declination,inclination,totalIntensity] = igrfmagm(Ls,lat,long,decyear(2019,10,15),12); 
    B_NRNC = igrf(decyear(2019,10,15),lat,long,Ls);
    % b_NRNC [nT] is local geomagnetic field vector with no rotation & no conversion
    % Z is the vertical component (+ve down) for the magnetic field vector
    % horIntensity [nT] is horizontal intensity
    % declination is in degrees (+ve east)
    % inclination is in degrees (+ve down)
    % totalIntensity in [nT]
    % THIS FUNCTIONS MODEL IS VALID BETWEEN THE YEARS OF 1900 AND 2020 -- MUST BE UPDATED UPON RELEASE OF NEW MODEL
    b_NR = (b_NRNC*1e-9).'; % [T] converted local geomagnetic field vector

    if i == 1 % initialize rotation values
        theta_x = 0; % [rad]
        theta_y = 0; % [rad]
        theta_z = 0; % [rad]
    else % update previous rotation position to current
        theta_x = theta_x+(omega_i(1)*dt)+(0.5*alpha_i(1)*dt^2); % [rad]
        theta_y = theta_y+(omega_i(2)*dt)+(0.5*alpha_i(2)*dt^2); % [rad]
        theta_z = theta_z+(omega_i(3)*dt)+(0.5*alpha_i(3)*dt^2); % [rad]
    end

    % direction cosine matrix (DCM) to translate obtained magnetic field vector to the satellite (body) frame of reference
    % converts from ECI to NED coordinates
    rx = [1,0,0;0,cos(theta_x),-sin(theta_x);0,sin(theta_x),cos(theta_x)];
    ry = [cos(theta_y),0,sin(theta_y);0,1,0;-sin(theta_y),0,cos(theta_y)];
    rz = [cos(theta_z),-sin(theta_z),0;sin(theta_z),cos(theta_z),0;0,0,1];
    b = rx*ry*rz*b_NR; % [T] local geomagnetic field vector translated and rotated onto the satellite (body)

    %% B-dot
    k = 1; % [Js/T] positive scalar control gain
    bdet = (sqrt(dot(b,b))); % [1/T] magnetic field vector determinant
    bdot = cross(b,omega_i); % [T/s] magnetic field vector derivative
    mu = -(k/bdet)*bdot; % [A*m^2] commanded magnetic dipole moment generated by magnetorquers
    atorque = cross(mu,b); % [Nm] torque produced by magnetic torque rods
    inertia_inv = inv(inertia); % [kg*m^2] inverse inertia matrix

    n = 300; % number of turns of wire ********NEEDS A REAL VALUE********
    A = 0.22; % [m^2] vector area of coil ********NEEDS A REAL VALUE********
    I_x = mu(1,1)/(n*A); % [Amps] current to run through x direction coil
    I_y = mu(1,2)/(n*A); % [Amps] current to run through y direction coil
    I_z = mu(1,3)/(n*A); % [Amps] current to run through z direction coil

    alpha_i = atorque*inertia_inv; % [rad/s^2] calculates new angular acceleration
    omega_i = omega_prev+(alpha_i*dt); % [rad/s] calculates new angular velocity

    disp('New angular velocity [omega_x, omega_y, omega_z]:');
    disp (omega_i);

    % update current, angle, angular velocity, and angular acceleration matrices
    I(i,1) = I_x; I(i,2) = I_y; I(i,3) = I_z;
    alpha(i,:) = alpha_i;
    omega(i,:) = omega_i;
    theta(i,1) = theta_x; theta(i,2) = theta_y; theta(i,3) = theta_z;
end

%% Plots
% Angular Acceleration
figure
hold on
plot(t/60,alpha(:,1));
plot(t/60,alpha(:,2));
plot(t/60,alpha(:,3));
hold off
title('CougSat-1 Angular Acceleration Post-ejection');
xlabel('Time [min] where 90 is 1 Orbit');
ylabel('\alpha [rad/s^2]');
legend('x','y','z');

% Angular Velocity
figure
hold on
plot(t/60,omega(:,1));
plot(t/60,omega(:,2));
plot(t/60,omega(:,3));
hold off
title('CougSat-1 Angular Velocity Post-ejection')
xlabel('Time [min] where 90 is 1 Orbit')
ylabel('\omega [rad/s]')
legend('x','y','z');

% Angular Position
figure
hold on
plot(t/60,theta(:,1));
plot(t/60,theta(:,2));
plot(t/60,theta(:,3));
hold off
title('CougSat-1 Angle Post-ejection')
xlabel('Time [min] where 90 is 1 Orbit')
ylabel('\theta [rad]')
legend('x','y','z');

% Current
figure
hold on
plot(t/60,I(:,1));
plot(t/60,I(:,2));
plot(t/60,I(:,3));
hold off
title('CougSat-1 Current Post-ejection')
xlabel('Time [min] where 90 is 1 Orbit')
ylabel('I [Amps]')
legend('x','y','z');
