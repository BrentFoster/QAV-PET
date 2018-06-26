function [intensity_range_for_exemplar, idx] = affinity_calculation(H, n, m, lambda, maxits)  
    N = length(H);
    distance_matrix = zeros(1,N);

    for i = 1:N-1            
        distance_matrix(i) = sqrt((H(i,1) - H(i+1,1))^2 + abs(H(i,2) - H(i+1,2))^2);      
    end
    
    row = 1;
    N = length(distance_matrix)-1;
    affinity_matrix = zeros(N^2,3);
    preference = zeros(N,1)+.5;
    for i = 1:N   
        for j = 1:N
           %The two data points being compared
           affinity_matrix(row,1) = H(i,1);
           affinity_matrix(row,2) = H(j,1);  
           if i>j            
                affinity_matrix(row,3) =  sqrt(abs(H(i,1) - H(j,1))^n +  sum(distance_matrix(j:i))^m);
            else     
                affinity_matrix(row,3) = sqrt(abs(H(i,1) - H(j,1))^n +  sum(distance_matrix(i:j))^m); 
            end      
           if j < N       
           row = row + 1;
           end
        end    
        if i < N
            row = row + 1;
        end 
    end

    %Subtract all the affinities from the max affinity value found!
    temp = max(affinity_matrix(:,3));
    affinity_matrix(:,3) = temp - affinity_matrix(:,3);

    [idx k c ]= apcluster(affinity_matrix, preference, 'dampfact',lambda, 'maxits', maxits);
    affinity_matrix=[];
    preference=[];

    exemplars = unique(idx);

    for i = 1:length(exemplars)
        [val] = find(idx == exemplars(i));
        intensity_range_for_exemplar{i} = val;
    end

end





