function drawMesh(faces, verts)
figure(4);
hold on;
trisurf(faces,verts(:,1),verts(:,2),verts(:,3),'FaceColor',[0.26,0.33,1.0 ], 'FaceAlpha', 0.5);
title('Room model');
xlabel('x [samples]');
ylabel('y [samples]');
zlabel('z [samples]');
end

