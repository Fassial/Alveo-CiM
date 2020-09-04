




function work_info_step2=train_step2(train_info, train_data, work_info_step2)


update_bit=work_info_step2.update_bit;
hash_learner_cache_info=work_info_step2.hash_learner_cache_info;

bi_train_data=[];
bi_train_data.feat_data=train_data.feat_data;
bi_train_data.label_data=double(work_info_step2.update_bi_code_step1);
bi_train_data.data_weight=work_info_step2.data_weights;
bi_train_data.hash_learner_idx=update_bit;


hash_learners_model=work_info_step2.hash_learners_model;
                

[hash_learner_info hash_learners_model hash_learner_cache_info hlearner_bi_code]=...
    train_hash_learner(train_info, bi_train_data, hash_learners_model, hash_learner_cache_info);


work_info_step2.hash_learners_model=hash_learners_model;
work_info_step2.hash_learner_infos{update_bit}=hash_learner_info;
work_info_step2.hash_learner_cache_info=hash_learner_cache_info;
work_info_step2.update_bi_code_step2=hlearner_bi_code;


    
end



function [hash_learner_info hash_learners_model cache_info hlearner_bi_code]=train_hash_learner(...
    train_info, bi_train_data, hash_learners_model, cache_info)



feat_data=bi_train_data.feat_data;
e_num=size(feat_data, 1);


if ~isempty(bi_train_data.data_weight)
    % make a normalization, to avoid the weight value too large or small..
    tmp_data_w=bi_train_data.data_weight;
    tmp_data_w=(length(tmp_data_w)/sum(tmp_data_w)).*tmp_data_w;
    bi_train_data.data_weight=tmp_data_w;
end


hash_learner_param=train_info.hash_learner_param;


tmp_t=tic;
[one_hash_learner, hash_learners_model, cache_info, hlearner_bi_code]=gen_hash_learner(...
    hash_learner_param, bi_train_data, hash_learners_model, cache_info);
train_t=toc(tmp_t);

assert(length(hlearner_bi_code)==e_num);


hash_learner_info=[];
hash_learner_info.hash_learner=one_hash_learner;

hash_learner_info.acc=NaN;
hash_learner_info.acc_weight=NaN;
hash_learner_info.apply_t=0;
hash_learner_info.train_t=train_t;


pos_sel=bi_train_data.label_data>0;
pos_num=nnz(pos_sel);


if (pos_num==0 || pos_num==e_num)
        
    fprintf('\n\n###WARNING: only one class label for gen_hash_learner, using random labels.\n\n');
    
    tmp_labels=randi(2, e_num, 1);
    tmp_labels(tmp_labels>1)=-1;
    pos_sel=tmp_labels>0;
    pos_num=nnz(pos_sel);
    bi_train_data.label_data=pos_sel;
end

hash_learner_info.e_num=e_num;
hash_learner_info.pos_num=pos_num;
hash_learner_info.neg_num=hash_learner_info.e_num-hash_learner_info.pos_num;
hash_learner_info.use_data_weight=~isempty(bi_train_data.data_weight);

[hash_learner_info.acc hash_learner_info.acc_weight]=calc_accuracy(hlearner_bi_code, bi_train_data.label_data,...
    bi_train_data.data_weight);


end




function [acc w_acc]=calc_accuracy(predict_labels, gt_labels, data_weight)
       
    correct_sel=gt_labels == predict_labels;
    acc=nnz(correct_sel)./length(correct_sel);
    
    w_acc=NaN;
    if ~isempty(data_weight)
        w_acc=sum(data_weight(correct_sel))./sum(data_weight);
    end
   
    
end






