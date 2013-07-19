%Summer Camp
close all
clear all

addpath 'C:\Documents and Settings\prclass\My Documents\MATLAB\MATLAB_LJUD\LJUD_Functions'

f0=1000;    %sample rate
Ts=1/f0;

[t,V]=LabJackU3('StreamAnalogIn',[0,1,2,3,4,5],f0,3);  %read in voltages from the labjack

Vx=V(2,:);
Vy=V(1,:);
Vz=V(3,:);

figure(1)
subplot(3,1,1) 
plot(t,Vx)
ylabel('Gyro V_x');
%axis([0 5 0 3.3])
subplot(3,1,2)
plot(t,Vy)
ylabel('Gyro V_y');
%axis([0 5 0 3.3])
subplot(3,1,3)
plot(t,Vz)
ylabel('Gyro V_z');
%axis([0 5 0 3.3])


wx=-(Vx- 1.330414816420525)/((180/pi)*3.753e-3);  %convert voltages into angular velocity
wy=-(Vy-1.334856309483449)/((180/pi)*3.753e-3);
wz=-(Vz-1.325237720496953)/((180/pi)*3.753e-3);

figure(2)
subplot(3,1,1)
plot(t,wx)
ylabel('\omega_x')
subplot(3,1,2)
plot(t,wy)
ylabel('\omega_y')
subplot(3,1,3)
plot(t,wz)
ylabel('\omega_z')

w=[wx.',wy.',wz.'].';

M=zeros(3,3,length(t));
M(:,:,1)=eye(3);

%integrate angular velocity into a direction cosine matrix
for i=1:length(t)-1
    M(:,:,i+1)=M(:,:,i)+Ts*M(:,:,i)*[0 -w(3,i) w(2,i);w(3,i) 0 -w(1,i);-w(2,i) w(1,i) 0];
end

