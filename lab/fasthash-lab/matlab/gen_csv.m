% author: fassial
% Created on September 4, 2020

function gen_csv()

% clear;
addpath(genpath([pwd '/']));

%--------------------------------------------------------------------------------------------------
% try these datasets:
% Our method aims for efficient training on large-scale and high-dimentional data.
% However, large scale and high-dimensional datasets are too large to be included in this source code.
% The advantage of FastHash will be more significant for large-scale training.
% The dataset MNIST is not a high-dimensional dataset, 
% but here it is just for demostration.
ds_file='./datasets/MNIST.mat';
ds_name='MNIST';

% change the following learning scale:
% select a subset as the dataset
max_ds_e_num=15000;
% max_ds_e_num=inf;
% the number of examples for training
max_trn_e_num=10000;

% set random seed
rand('seed', 1);

% load data
disp('load dataset...');
% load the demo dataset:
ds=load(ds_file);
ds=ds.dataset;
if issparse(ds.x)
    disp('warning! using sparse dataset, it may be slow if it is not really sparse!');
end

e_num=length(ds.y);
if e_num>max_ds_e_num
    ds_e_sel_idxes=randsample(e_num, max_ds_e_num);
    ds.x=ds.x(ds_e_sel_idxes,:);
    ds.y=ds.y(ds_e_sel_idxes,:);
end

% As a simple demo, turn this on to test high-dimensional training speed.
% Currently it is turned off.

do_increase_dim=false;
% do_increase_dim=true;

if do_increase_dim
    disp('randomly increase dimension for simple demostration...');
    % to randomly increase its dimension, just to evaluate the training speed
    ds.x=double(ds.x);
    new_x=ds.x;
    for tmp_i=1:10
        dim_idx1=randperm(size(ds.x, 2));
        one_new_x=sqrt(ds.x(:, dim_idx1).*ds.x);
        new_x=cat(2, new_x, one_new_x);
    end
    ds.x=new_x;
end






% here is a very simple way to split training data, just for demo

e_num=length(ds.y);
tst_e_num=min(2000, round(e_num*0.3));
tst_sel=false(e_num,1);
tst_sel(randsample(e_num,tst_e_num))=true;
ds.test_inds=find(tst_sel);

database_sel=~tst_sel;
ds.db_inds=find(database_sel);

db_e_num=length(ds.db_inds);
trn_e_num=min(max_trn_e_num, db_e_num);
ds.train_inds=ds.db_inds(randsample(db_e_num,trn_e_num));


database_data=[];
database_data.feat_data=ds.x(ds.db_inds,:);
database_data.label_data=ds.y(ds.db_inds);

train_data=[];
train_data.feat_data=ds.x(ds.train_inds,:);
train_data.label_data=ds.y(ds.train_inds);

test_data=[];
test_data.feat_data=ds.x(ds.test_inds,:);
test_data.label_data=ds.y(ds.test_inds);

clear ds

% save data
save_data(database_data, train_data, test_data, "raw");

% start train
fprintf('\n\n\n ================ traning examples:%d, feature dimension:%d \n\n\n', ...
    size(train_data.feat_data, 1), size(train_data.feat_data, 2));
pause(3);




%--------------------------------------------------------------------------------------------------
% evaluation setting:

% try larger bits: 32, 64, 512 ...
bit_num=8;

label_type='multiclass';

db_label_info.label_data=database_data.label_data;
db_label_info.label_type=label_type;

test_label_info.label_data=test_data.label_data;
test_label_info.label_type=label_type;

code_data_info=[];
code_data_info.db_label_info=db_label_info;
code_data_info.test_label_info=test_label_info;

eva_bit_step=round(min(8, bit_num/4));
eva_bits=eva_bit_step:eva_bit_step:bit_num;

eva_param=[];
eva_param.eva_top_knn_pk=100;
eva_param.eva_bits=eva_bits;
eva_param.code_data_info=code_data_info;

%-----------------------------------------------

% run FastHash:
fasthash_predict_result=gc_do_run_fasthash(database_data, train_data, test_data, eva_param);

end

function [database_data, train_data, test_data]=gc_convert_double(database_data, train_data, test_data)
    database_data.feat_data=double(database_data.feat_data);
    train_data.feat_data=double(train_data.feat_data);
    test_data.feat_data=double(test_data.feat_data);
end


function [database_data, train_data, test_data]=convert_single(database_data, train_data, test_data)
    database_data.feat_data=single(database_data.feat_data);
    train_data.feat_data=single(train_data.feat_data);
    test_data.feat_data=single(test_data.feat_data);
end

function [database_data, train_data, test_data]=gc_do_normalization(database_data, train_data, test_data)
    % do normalization. if using boosted tree hash function, this is not necessary.

    disp('data normalization...');

    assert(isa(train_data.feat_data, 'single') || isa(train_data.feat_data, 'double'));

    max_dims=max(train_data.feat_data,[],1);
    min_dims=min(train_data.feat_data,[],1);
    range_dims=max_dims-min_dims+eps;


    database_data.feat_data = bsxfun(@minus, database_data.feat_data, min_dims);
    database_data.feat_data = bsxfun(@rdivide, database_data.feat_data, range_dims);

    train_data.feat_data = bsxfun(@minus, train_data.feat_data, min_dims);
    train_data.feat_data = bsxfun(@rdivide, train_data.feat_data, range_dims);

    test_data.feat_data = bsxfun(@minus, test_data.feat_data, min_dims);
    test_data.feat_data = bsxfun(@rdivide, test_data.feat_data, range_dims);
end

function [database_data, train_data, test_data]=gc_do_quantization(database_data, train_data, test_data)
    disp('quantizing data...');

    % for using efficient decision tree hash function, we quantize the data into unsigned int8.
    quantize_info=gen_quantize_info(train_data.feat_data);

    database_data.feat_data=quantize_data(database_data.feat_data, quantize_info);
    train_data.feat_data=quantize_data(train_data.feat_data, quantize_info);
    test_data.feat_data=quantize_data(test_data.feat_data, quantize_info);
end

function hash_learner_param=gc_set_rbf_kernel_param(hash_learner_param, train_data)
    % this is a simple example for picking the RBF kernel parameter sigma
    % user should tune this parameter, e.g., try to pick v from [0.1 1 5 10].

    trn_feat_data=train_data.feat_data;
    rbf_knn=50;
    if size(trn_feat_data,1)>1e4
        trn_feat_data=trn_feat_data(randsample(size(trn_feat_data,1), 1e4),:);
    end
    sq_eudist = sqdist(trn_feat_data',trn_feat_data');
    sq_eudist=sort(sq_eudist,2);
    sq_eudist=sq_eudist(:,1:rbf_knn);
    sq_sigma = mean(sq_eudist(:));
    sq_sigma=sq_sigma+eps;

    % this need to tune, try to pick v from [0.1 0.5 1 5 10]
    v=0.5;
    hash_learner_param.sigma=sq_sigma*v;
end

function fasthash_predict_result=gc_do_run_fasthash(database_data, train_data, test_data, eva_param)

    % generate pairwise affinity ground truth for supervised hashing learning:
    % a simple example is shown here for dataset with multi-class labels.
    % users can replace this ground truth definition here according to your applications.
    % this similarity labels can be cached.
    disp('generate affinity information...');

    affinity_labels=gen_affinity_labels(train_data);
    trn_e_num=size(train_data.feat_data, 1);
    assert(size(affinity_labels, 1)==trn_e_num);
    assert(size(affinity_labels, 2)==trn_e_num);
    train_data.relation_info=gen_relation_info(affinity_labels);

    disp('constructing blocks for inference...');
    % generate inference blocks for block GraphCut. 
    % note that blocks can be cached, rather than constructing every time.
    % there are many different ways to construct blocks, here we provide two examples:

    % if using multi-class or multi-label dataset, we can use the class label to define blocks:
    infer_block_info=gen_infer_block_multiclass(train_data.label_data);

    % if using general dataset, not multi-class dataset, 
    % we can use the following to define blocks in a general way:
    % infer_block_info=gen_infer_block(train_data.relation_info);
    % preprocessing finished.
    %--------------------------------------------------------------------------------------------------

    disp('configuration before training...');
    
    bit_num=eva_param.eva_bits(end);
    fasthash_train_info=[];
    fasthash_train_info.bit_num=bit_num;

    % choices for binary code inference methods:
    fasthash_train_info.binary_infer_method='block_graphcut';
    % fasthash_train_info.binary_infer_method='spectral';

    if strcmp(fasthash_train_info.binary_infer_method, 'block_graphcut')
        fasthash_train_info.infer_info=infer_block_info;
        
        % block GraphCut iteration:
        fasthash_train_info.infer_iter_num=2;
    end

    % choices for loss function, you could add your own loss function.
    % Hinge loss usually performs the best.
    % fasthash_train_info.hash_loss_type='KSH';
    fasthash_train_info.hash_loss_type='Hinge';
    % fasthash_train_info.hash_loss_type='BRE';

    % classifier setting for Step-2, users can use any customized classifier, 
    % some examples are included here:
    classifier_type='boost_tree';

    hash_learner_param=[];
    hash_learner_param.bit_num=bit_num;
    hash_learner_param.classifier_type=classifier_type;

    if strcmp(classifier_type, 'boost_tree')
        % use quantized data
        [database_data, train_data, test_data]=gc_do_quantization(database_data, train_data, test_data);

        % boosting iteration:
        hash_learner_param.max_wl_num=[200];

        % this tree depth  need to tune. large dataset requires a large depth.
        % usually large depth will have a good precision, but will be slower.
        % , try different settings: 2, 4, 6, 8, 10, 12. 
        hash_learner_param.tree_depth=[4];

        % Weighting trimming for boosting learning. 
        % Larger value will result better accuracy, but would get slower.
        % Try values from 0.9 to 0.99. 
        hash_learner_param.mass_weight_thresh=0.99;

        % lazyboost setting. 
        % how many dimensions are considered for tree node splitting:
        hash_learner_param.tree_node_feat_num=200;

        % here for setting how many examples are considered for tree node splitting.
        % currrently this is not turnning on.
        % hash_learner_param.tree_node_e_num=1e4;
    end

    fasthash_train_info.hash_learner_param=hash_learner_param;

    fasthash_train_result=fasthash_train(fasthash_train_info, train_data);
    fasthash_model=fasthash_train_result.model;

    % save fasthash_model & data
    save_fasthash_model(fasthash_model);
    save_data(database_data, train_data, test_data, "preprocess");

    % fasthash encode
    fasthash_db_data_code=fasthash_encode(fasthash_model, database_data.feat_data);
    fasthash_tst_data_code=fasthash_encode(fasthash_model, test_data.feat_data);
    % save encode
    save_encode(fasthash_db_data_code, fasthash_tst_data_code);

    % generate compact code if it is needed:
    % fasthash_db_data_code_compact=gen_compactbit(fasthash_db_data_code);

    % set to []
    fasthash_predict_result=[];

end

function save_fasthash_model(fasthash_model)
    prefix = fullfile("..", "model");
    if exist(prefix, 'dir')
        rmdir(prefix, 's');
    end
    mkdir(prefix);
    % get hash_learners
    hash_learners = fasthash_model.hs;
    bit_num=length(hash_learners);
    for h_idx=1:bit_num
        % set model_path
        model_path = fullfile(prefix, "tree" + num2str(h_idx));
        mkdir(model_path);
        % get corresponding model
        model=hash_learners{h_idx};
        % save w & sel_feat_idxes
        csvwrite(fullfile(model_path, "w.csv"), model.w);
        csvwrite(fullfile(model_path, "sel_feat_idxes.csv"), model.sel_feat_idxes);
        % save wl_model
        wl_model_path = fullfile(model_path, "tree_models");
        mkdir(wl_model_path);
        wl_model = model.wl_model.tree_models;
        len_wl_model = length(wl_model);
        for wl_idx=1:len_wl_model
            % set tree_model_path
            tree_model_path = fullfile(wl_model_path, num2str(wl_idx));
            mkdir(tree_model_path);
            % get tree_model
            tree_model = wl_model{wl_idx};
            % save tree_model
            csvwrite(fullfile(tree_model_path, "fids.csv"), tree_model.fids);
            csvwrite(fullfile(tree_model_path, "thrs.csv"), tree_model.thrs);
            csvwrite(fullfile(tree_model_path, "child.csv"), tree_model.child);
            csvwrite(fullfile(tree_model_path, "hs.csv"), tree_model.hs);
            csvwrite(fullfile(tree_model_path, "weights.csv"), tree_model.weights);
            csvwrite(fullfile(tree_model_path, "depth.csv"), tree_model.depth);
            csvwrite(fullfile(tree_model_path, "e_sel_time.csv"), tree_model.e_sel_time);
            csvwrite(fullfile(tree_model_path, "train_time.csv"), tree_model.train_time);
            csvwrite(fullfile(tree_model_path, "other_time.csv"), tree_model.other_time);
            csvwrite(fullfile(tree_model_path, "total_time.csv"), tree_model.total_time);
            csvwrite(fullfile(tree_model_path, "max_feat_num.csv"), tree_model.max_feat_num);
            csvwrite(fullfile(tree_model_path, "max_e_num.csv"), tree_model.max_e_num);
            csvwrite(fullfile(tree_model_path, "sel_feat_idxes.csv"), tree_model.sel_feat_idxes);
            csvwrite(fullfile(tree_model_path, "mean_confidence.csv"), tree_model.mean_confidence);
        end
    end
end

function save_data(database_data, train_data, test_data, postfix)
    % get rootdir
    prefix = fullfile("..", "dataset");
    if ~exist(prefix, 'dir')
        mkdir(prefix);
    end
    % get subdir
    prefix = fullfile(prefix, postfix);
    if exist(prefix, 'dir')
        rmdir(prefix, 's');
    end
    mkdir(prefix);
    % store data
    csvwrite(fullfile(prefix, "db_feature.csv"), database_data.feat_data);
    csvwrite(fullfile(prefix, "db_label.csv"), database_data.label_data);
    csvwrite(fullfile(prefix, "train_feature.csv"), train_data.feat_data);
    csvwrite(fullfile(prefix, "train_label.csv"), train_data.label_data);
    csvwrite(fullfile(prefix, "test_feature.csv"), test_data.feat_data);
    csvwrite(fullfile(prefix, "test_label.csv"), test_data.label_data);
end

function save_encode(fasthash_db_data_code, fasthash_tst_data_code)
    % get rootdir
    prefix = fullfile("..", "encode");
    if ~exist(prefix, 'dir')
        mkdir(prefix);
    end
    % get subdir
    prefix = fullfile(prefix, "matlab");
    if exist(prefix, 'dir')
        rmdir(prefix, 's');
    end
    mkdir(prefix);
    % store encode
    csvwrite(fullfile(prefix, "db_encode.csv"), fasthash_db_data_code);
    csvwrite(fullfile(prefix, "test_encode.csv"), fasthash_tst_data_code);
end
