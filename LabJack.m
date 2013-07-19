clc;
clear;

format long;

f0 = 1000; %sample rate

%Run experiment to get initial offset
[t,V] = LabJackU3('StreamAnalogIn',[0,1,2],f0,5);

Vx0 = mean(V(2,:));
Vy0 = mean(V(1,:));
Vz0 = mean(V(3,:));


%Run experiment to get movement values
[t,V] = LabJackU3('StreamAnalogIn',[0,1,2],f0,5);

Vx = V(2,:);
Vy = V(1,:);
Vz = V(3,:);


save 'Lab2data.mat' Vx0 Vy0 Vz0 Vx Vy Vz t

