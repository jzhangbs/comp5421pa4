addpath(genpath('./gco/'));

%% generate icosphere
disp('generate icosphere');
[v,~] = icosphere(4);
v = v(v(:,3)>=0,:);

%% read data
disp('read data');
dataset_path = 'data/data08';
lightvec_raw = load(fullfile(dataset_path, 'lightvec.txt'));
N_raw = length(lightvec_raw);
images_path = dir(fullfile(dataset_path, '*.bmp'));
test_image = imread(fullfile(dataset_path, images_path(1).name));
image_size = size(test_image);
image_size = [image_size(1) image_size(2)];
images_raw = zeros([N_raw image_size]);
for i = 1:N_raw
    images_raw(i, :, :) = double(rgb2gray(imread(fullfile(dataset_path, images_path(i).name))));
end

%% resample
disp('resample');
[nn_index,~]=knnsearch(v,lightvec_raw);
[unique_nn_index,~,unique2origin] = unique(nn_index);
N = length(unique_nn_index);
images = zeros([N image_size]);
denom = zeros(N,1);
for i = 1:N_raw
    denom(unique2origin(i)) = denom(unique2origin(i)) + lightvec_raw(i,:)*v(nn_index(i),:)';
    images(unique2origin(i),:,:) = images(unique2origin(i),:,:) + lightvec_raw(i,:)*v(nn_index(i),:)'*images_raw(i,:,:);
end
for i = 1:N
    images(i,:,:) = images(i,:,:)/denom(i);
end
lightvec = v(unique_nn_index,:);

%% denominator image
disp('denominator image');
percentile = zeros([N image_size]);
rank_indicator = zeros([N image_size]);
for i = 1:image_size(1)
    for j = 1:image_size(2)
        [~,sort_index] = sort(images(:,i,j));
        order = zeros(N,1);
        order(sort_index) = 1:N;
        percentile(:, i, j) = order/N;
        rank_indicator(:, i, j) = percentile(:, i, j)>0.7;
    end
end
kL = squeeze(sum(sum(rank_indicator, 2), 3));
ave_rL = squeeze(sum(sum(rank_indicator.*percentile, 2), 3))./(kL+1e-9);
[~, rL_sort_index] = sort(ave_rL);
order(rL_sort_index) = 1:N;
rL_percentile = order/N;
rL_rank_indicator = rL_percentile<0.9;
[~, denom_index] = max(kL.*rL_rank_indicator);

%% local norm
disp('local norm');
A = zeros(N-1,3);
local_norm = zeros([image_size 3]);
for i = 1:image_size(1)
    for j = 1:image_size(2)
        kp = 1;
        for k = 1:N
            if k == denom_index
                continue
            end
            A(kp, :) = images(k,i,j)*lightvec(denom_index,:)-images(denom_index,i,j)*lightvec(k,:);
            kp = kp + 1;
        end
        [U,S,V] = svd(A,0);
        local_norm(i,j,:) = ( V(:,3)*(V(3,3)/abs(V(3,3))) )';
    end
end

%% refine
disp('refine');

% parameter
sigma = 0.75;
lambda = 0.5;

% create
disp('  create');
[norm_v,~] = icosphere(5);
norm_v = norm_v(norm_v(:,3)>=0,:);
h = GCO_Create(prod(image_size), length(norm_v));

% set init label
disp('  set init label');
local_norm_flat = reshape(local_norm, [], 3);
[norm_nn_index, ~] = knnsearch(norm_v, local_norm_flat);
GCO_SetLabeling(h, norm_nn_index);

% set cost
disp('  set cost');
Ed = int32(pdist2(norm_v, local_norm_flat)*10000);
Es = int32(lambda * log(1 + pdist2(norm_v, norm_v) / (2*sigma^2))*10000);
GCO_SetDataCost(h, Ed);
GCO_SetSmoothCost(h, Es);

% set neighbor
disp('  set neighbor');
adj = sparse(prod(image_size),prod(image_size));
for i = 1:image_size(1)-1
    for j = 1:image_size(2)
        adj((i-1)*image_size(2)+j, i*image_size(2)+j) = 1;
    end
end
for i = 1:image_size(1)
    for j = 1:image_size(2)-1
        adj((i-1)*image_size(2)+j, (i-1)*image_size(2)+j+1) = 1;
    end
end
GCO_SetNeighbors(h, adj);

% graph cut
disp('  graph cut');
GCO_Expansion(h);
norm_index = GCO_GetLabeling(h);
GCO_Delete(h);
norm_flat = norm_v(norm_index, :);
refine_norm = reshape(norm_flat, image_size(1), image_size(2), 3);

%% visualize
disp('visualize');
slant = zeros(image_size);
tilt = zeros(image_size);
for i = 1:image_size(1)
    for j = 1:image_size(2)
        [slant(i,j), tilt(i,j)] = grad2slanttilt(-refine_norm(image_size(1)+1-i,j,1)/refine_norm(image_size(1)+1-i,j,3),-refine_norm(image_size(1)+1-i,j,2)/refine_norm(image_size(1)+1-i,j,3));
    end
end
depth_map = shapeletsurf(slant, tilt, 6, 3, 2);
figure, imshow(local_norm);
figure, imshow(refine_norm);

texture = imread(fullfile(dataset_path, images_path(denom_index).name));
texture = texture(image_size(1):-1:1,:,:);
figure, surf(depth_map, 'FaceColor','Cyan','EdgeColor','none'),camlight left,lighting phong,axis equal,axis vis3d,axis off;
figure, surf(depth_map, texture,'FaceColor','texturemap','EdgeColor','none'),camlight left,lighting phong,axis equal,axis vis3d,axis off;