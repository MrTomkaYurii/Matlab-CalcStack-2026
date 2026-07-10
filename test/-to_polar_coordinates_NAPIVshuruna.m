function POLAR_OUT_2D = to_polar_coordinates_NAPIVshuruna(correlation_matrix)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% перев≥д в POLAR_OUT пол€рну систему координат
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[M N C]=size(correlation_matrix);
RAD=floor(sqrt((M/2)^2+(N/2)^2));

for i=drange(1,RAD)
    for j=drange(1,360)
        [X Y]=(pol2cart((j-1)*2*pi/360,i-1));
        X=X+M/2;
        Y=Y+N/2;
        if(X>=0 && X<=M && Y<=N && Y>=0)
        X=round(X);
        Y=round(Y);
        X=X+(X==0);
        Y=Y+(Y==0);
        
        if C>1
        POLAR_OUT(i,j,:)= correlation_matrix(X,Y,:);
        else
        POLAR_OUT(i,j)= correlation_matrix(X,Y);            
        end
        
        end
    end
end

POLAR_OUT_2D = POLAR_OUT;

end
