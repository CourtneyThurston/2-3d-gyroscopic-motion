function Cartoon=animate_dcm(t,M);

%Use: Cartoon=animate_quaternion(t,q)
%Here t is a time vector and q is a matrix whose columns are
%unit-quaternions at the instances in t.  
%This function generates a 400 frame animation of the rotation applied to a
%cube.

frames=400;
counter=1;
W=5;
L=5;
h=5;
for i=1:length(t)/(frames-1):length(t)
    figure(99)
    i=round(i);
   T_body_to_reference=[M(:,:,i),zeros(3,1);zeros(1,3),1];
    box_vertex=[...
                        W/2   -L/2  h/2   1;...
                        W/2   L/2   h/2   1;...
                        W/2   L/2   -h/2  1;...
                        W/2   -L/2  -h/2  1;...
                        -W/2  -L/2  h/2   1;...
                        -W/2  L/2   h/2   1;...
                        -W/2  L/2   -h/2  1;...
                        -W/2  -L/2  -h/2  1];
 
    box_faces=[...
                        1 2 3 4;...
                        5 6 2 1;...
                        8 7 6 5;...
                        4 3 7 8;...
                        5 1 4 8;...
                        6 2 3 7];
                
    box=(T_body_to_reference*box_vertex')';            
    P1=patch('Vertices',box(:,1:3),'Faces',box_faces,'FaceVertexCData',hsv(6),'FaceColor','flat');
    hold on
    P2=plot3([0 10],[0 0],[0 0]);
    P3=plot3([0 0],[0 10],[0 0]);
    P4=plot3([0 0],[0 0],[0 10]);
    P5=text([12],[0],[0],'x');
    axis equal
    axis([-15,15,-15,15,-15,15])
    view([.5,-1,.5]);
    grid on
    Cartoon(counter)=getframe(99);
    if counter~=frames-1
        delete(P1);      
        delete(P2);
        delete(P3);
        delete(P4);
        delete(P5);
    end
    counter=counter+1;
    
end
xlabel('x')
ylabel('y')
zlabel('z')


