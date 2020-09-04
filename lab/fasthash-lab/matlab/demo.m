


% Code author: Guosheng Lin. 
% Contact: guosheng.lin@gmail.com or guosheng.lin@adelaide.edu.au


% Please cite this paper: 
% "Fast Supervised Hashing with Decision Trees for High-Dimensional Data"; CVPR2014
% Guosheng Lin, Chunhua Shen, Qinfeng Shi, Anton van den Hengel and David Suter.



% Decision tree training requires multi-threading.

function fasthash_demo()


% clear;

addpath(genpath([pwd '/']));



%--------------------------------------------------------------------------------------------------
% load data



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
%  max_ds_e_num=inf;
 % the number of examples for training
 max_trn_e_num=10000;

 


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
do_increase_dim=true;

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

predict_results=cell(0);



%-----------------------------------------------


% run FastHash:

fasthash_predict_result=do_run_fasthash(database_data, train_data, test_data, eva_param);
predict_results{end+1}=fasthash_predict_result;


% run LSH for a simple comparison:
lsh_predict_result=do_run_lsh(database_data, train_data, test_data, eva_param);
predict_results{end+1}=lsh_predict_result;




%-----------------------------------------------
% plot results


f1=figure;
line_width=2;
xy_font_size=22;
marker_size=10;
legend_font_size=15;
xy_v_font_size=15;
title_font_size=xy_font_size;

legend_strs=cell(length(predict_results), 1);

for p_idx=1:length(predict_results)
    
    predict_result=predict_results{p_idx};
   
    fprintf('\n\n-------------predict_result--------------------------------------------------------\n\n');
    disp(predict_result);

    color=gen_color(p_idx);
    marker=gen_marker(p_idx);
    
    x_values=eva_bits;
    y_values=predict_result.pk100_eva_bits;

    p=plot(x_values, y_values);
    
    set(p,'Color', color)
    set(p,'Marker',marker);
    set(p,'LineWidth',line_width);
    set(p,'MarkerSize',marker_size);
    
    legend_strs{p_idx}=[predict_result.method_name  sprintf('(%.3f)', y_values(end))];
    
    hold all
end


hleg=legend(legend_strs);
h1=xlabel('Number of bits');
h2=ylabel('Precision @ K (K=100)');
title(ds_name, 'FontSize', title_font_size);

set(gca,'XTick',x_values);
xlim([x_values(1) x_values(end)]);
set(hleg, 'FontSize',legend_font_size);
set(hleg,'Location','SouthEast');
set(h1, 'FontSize',xy_font_size);
set(h2, 'FontSize',xy_font_size);
set(gca, 'FontSize',xy_v_font_size);
set(hleg, 'FontSize',legend_font_size);
grid on;
hold off



end




function [database_data, train_data, test_data]=convert_double(database_data, train_data, test_data)


database_data.feat_data=double(database_data.feat_data);
train_data.feat_data=double(train_data.feat_data);
test_data.feat_data=double(test_data.feat_data);

end


function [database_data, train_data, test_data]=convert_single(database_data, train_data, test_data)

database_data.feat_data=single(database_data.feat_data);
train_data.feat_data=single(train_data.feat_data);
test_data.feat_data=single(test_data.feat_data);

end




function [database_data, train_data, test_data]=do_normalization(database_data, train_data, test_data)

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





function [database_data, train_data, test_data]=do_quantization(database_data, train_data, test_data)


disp('quantizing data...');

% for using efficient decision tree hash function, we quantize the data into unsigned int8.
quantize_info=gen_quantize_info(train_data.feat_data);

database_data.feat_data=quantize_data(database_data.feat_data, quantize_info);
train_data.feat_data=quantize_data(train_data.feat_data, quantize_info);
test_data.feat_data=quantize_data(test_data.feat_data, quantize_info);

end



function hash_learner_param=set_rbf_kernel_param(hash_learner_param, train_data)

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






function fasthash_predict_result=do_run_fasthash(database_data, train_data, test_data, eva_param)




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
%     fasthash_train_info.binary_infer_method='spectral';
    
    if strcmp(fasthash_train_info.binary_infer_method, 'block_graphcut')
        fasthash_train_info.infer_info=infer_block_info;
        
        % block GraphCut iteration:
        fasthash_train_info.infer_iter_num=2;
    end
    

    % choices for loss function, you could add your own loss function.
    % Hinge loss usually performs the best.
    
%    fasthash_train_info.hash_loss_type='KSH';
     fasthash_train_info.hash_loss_type='Hinge';
%     fasthash_train_info.hash_loss_type='BRE';
    	    


% classifier setting for Step-2, users can use any customized classifier, 
	% some examples are included here:
    
     classifier_type='boost_tree';
%     classifier_type='svm_linear';
%     classifier_type='svm_rbf_kernel_feat';
%     classifier_type='svm_rbf'; 
%     classifier_type='svm_rbf_budgeted';





	hash_learner_param=[];
    hash_learner_param.bit_num=bit_num;
	hash_learner_param.classifier_type=classifier_type;

	
    
    if strcmp(classifier_type, 'boost_tree')
        
       
        % use quantized data
        [database_data, train_data, test_data]=do_quantization(database_data, train_data, test_data);
        
        
        %boosting iteration:
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
       %hash_learner_param.tree_node_e_num=1e4;
    	
    end


    
    if strcmp(classifier_type, 'svm_linear')
        
        if ~issparse(train_data.feat_data)
            [database_data, train_data, test_data]=convert_single(database_data, train_data, test_data);
        else
            [database_data, train_data, test_data]=convert_double(database_data, train_data, test_data);
        end
        
        [database_data, train_data, test_data]=do_normalization(database_data, train_data, test_data);
        
        % setting the trainoff param of SVM, try [1e5 1e6 1e7 1e8]
        hash_learner_param.tradeoff_param=1e6;
        
    end
       


	if strcmp(classifier_type, 'svm_rbf_kernel_feat') 
        
        if ~issparse(train_data.feat_data)
            [database_data, train_data, test_data]=convert_single(database_data, train_data, test_data);
        else
            [database_data, train_data, test_data]=convert_double(database_data, train_data, test_data);
        end
        
        [database_data, train_data, test_data]=do_normalization(database_data, train_data, test_data);
        hash_learner_param=set_rbf_kernel_param(hash_learner_param, train_data);
        
        
        % setting the trainoff param of SVM, try [1e5 1e6 1e7 1e8]
        hash_learner_param.tradeoff_param=1e6;
        
        
        trn_feat_data=train_data.feat_data;
        
	    % random select support vectors, as an alternative, user can use
	    % k-means for setting this support_vectors.
 	    sv_num=500;
	    sv_num=min(sv_num, size(trn_feat_data, 1));
	    support_vectors=trn_feat_data(randsample(size(trn_feat_data, 1), sv_num),:);
	    hash_learner_param.support_vectors=support_vectors;
        
        
    end

    
    if strcmp(classifier_type, 'svm_rbf')
        
        % LibSVM require sparse double input:
        [database_data, train_data, test_data]=convert_double(database_data, train_data, test_data);
        [database_data, train_data, test_data]=do_normalization(database_data, train_data, test_data);
        hash_learner_param=set_rbf_kernel_param(hash_learner_param, train_data);
        
        % setting the trainoff param of SVM, try [1e4 1e5 1e6 1e7]
        hash_learner_param.tradeoff_param=1e5;
    end


    
    if strcmp(classifier_type, 'svm_rbf_budgeted')
        
        [database_data, train_data, test_data]=convert_double(database_data, train_data, test_data);
        
        [database_data, train_data, test_data]=do_normalization(database_data, train_data, test_data);
        hash_learner_param=set_rbf_kernel_param(hash_learner_param, train_data);
                
        
        % setting the trainoff param of SVM, try [1e4 1e5 1e6 1e7]
        hash_learner_param.tradeoff_param=1e6;
        
                
        hash_learner_param.epoch_num=10;
        
        % the budget of support vectors:
        hash_learner_param.budget=500;
    end


	
	fasthash_train_info.hash_learner_param=hash_learner_param;

    fasthash_train_result=fasthash_train(fasthash_train_info, train_data);
    fasthash_model=fasthash_train_result.model;

    
    fasthash_db_data_code=fasthash_encode(fasthash_model, database_data.feat_data);
    fasthash_tst_data_code=fasthash_encode(fasthash_model, test_data.feat_data);


    % generate compact code if it is needed:
    % fasthash_db_data_code_compact=gen_compactbit(fasthash_db_data_code);
    

    disp('doing FastHash evaluation...');
    
    eva_bits=eva_param.eva_bits;
    code_data_info=eva_param.code_data_info;
    
    fasthash_predict_result=[];
    fasthash_predict_result.method_name='FastHash';
    fasthash_predict_result.eva_bits=eva_bits;
    for b_idx=1:length(eva_bits)
        one_bit_num=eva_bits(b_idx);
        fasthash_code_data_info=code_data_info;
        fasthash_code_data_info.db_data_code=fasthash_db_data_code(:, 1:one_bit_num);
        fasthash_code_data_info.tst_data_code=fasthash_tst_data_code(:, 1:one_bit_num);
        one_bit_result=hash_evaluate(eva_param, fasthash_code_data_info);
        fasthash_predict_result.pk100_eva_bits(b_idx)=one_bit_result.pk100;
    end
        

end





function lsh_predict_result=do_run_lsh(database_data, train_data, test_data, eva_param)

    bit_num=eva_param.eva_bits(end);
    
    if ~issparse(train_data.feat_data)
        [database_data, train_data, test_data]=convert_single(database_data, train_data, test_data);
    else
        [database_data, train_data, test_data]=convert_double(database_data, train_data, test_data);
    end
    
    [database_data, train_data, test_data]=do_normalization(database_data, train_data, test_data);

    lsh_model=LSH_learn(train_data.feat_data, bit_num);
    lsh_db_data_code=LSH_compress(database_data.feat_data, lsh_model);
    lsh_tst_data_code=LSH_compress(test_data.feat_data, lsh_model);

    disp('doing LSH evaluation...');
    eva_bits=eva_param.eva_bits;
    code_data_info=eva_param.code_data_info;

    lsh_predict_result=[];
    lsh_predict_result.method_name='LSH';
    lsh_predict_result.eva_bits=eva_bits;
    for b_idx=1:length(eva_bits)
        one_bit_num=eva_bits(b_idx);
        lsh_code_data_info=code_data_info;
        lsh_code_data_info.db_data_code=lsh_db_data_code(:, 1:one_bit_num);
        lsh_code_data_info.tst_data_code=lsh_tst_data_code(:, 1:one_bit_num);
        one_bit_result=hash_evaluate(eva_param, lsh_code_data_info);
        lsh_predict_result.pk100_eva_bits(b_idx)=one_bit_result.pk100;
    end
    

end



