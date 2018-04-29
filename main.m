addpath(genpath('./gco/'));

%% generate icosphere
disp('generate icosphere');
[v,~] = icosphere(4);
v = v(v(:,3)>=0,:);

%% read data
disp('read data');
dataset_path = 'data/data04';
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
norm = local_norm;

%% visualize
disp('visualize');
slant_tilt = zeros([image_size 2]);
for i = 1:image_size(1)
    for j = 1:image_size(2)
        slant_tilt(i,j,:) = grad2slanttilt(-norm(i,j,1)/norm(i,j,3),-norm(i,j,2)/norm(i,j,3));
    end
end
depth_map = shapeletsurf(slant_tilt(:,:,1), slant_tilt(:,:,2), 6, 3, 2);
figure, imshow(norm);
figure, surf(depth_map);