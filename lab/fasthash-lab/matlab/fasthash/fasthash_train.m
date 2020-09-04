

% Code author: Guosheng Lin. Contact: guosheng.lin@gmail.com or guosheng.lin@adelaide.edu.au


function train_result=fasthash_train(train_info, train_data)

fprintf('\n\n------------------------------fasthash_train---------------------------\n\n');


if ~isfield(train_info, 'train_id')
	train_info.train_id='FastHash';
end

train_info=config_train_info(train_info);

train_info.e_num=size(train_data.feat_data, 1);
   
train_result=do_train(train_info, train_data);


fprintf('\n\n------------------------------fasthash_train finished---------------------------\n\n');

end




function train_result=do_train(train_info, train_data)


relation_info=train_data.relation_info;

work_info_step1=gen_work_info_step1(relation_info);
work_info_step1=gen_loss_info(train_info, work_info_step1);
work_info_step1.init_infer_info=gen_infer_info(train_info, work_info_step1);
work_info_step1.data_weights=[];



work_info_step2=[];
work_info_step2.hash_learner_infos=cell(train_info.bit_num, 1);
work_info_step2.hash_learners_model=[];
work_info_step2.hash_learner_cache_info=[];


time_info=[];
time_info.method_time_tic=tic;
time_info.method_time=0;
time_info.time_step1=0;
time_info.time_step2=0;
time_info.one_time_step1=0;
time_info.one_time_step2=0;
time_info.data_w_time=0;
time_info.method_time_bits=zeros(train_info.bit_num, 1);


[work_info_step1, work_info_step2, time_info]=do_train_stage(train_info, train_data, work_info_step1, work_info_step2, time_info);

time_info.method_time=toc(time_info.method_time_tic);

train_result=gen_train_result(train_info, work_info_step1, work_info_step2, time_info);

end




function [work_info_step1, work_info_step2, time_info]=do_train_stage(...
    train_info, train_data, work_info_step1, work_info_step2, time_info)


train_info.use_data_weight=true;

if ~train_info.train_stagewise
    bi_code_bits=ones(train_info.e_num, train_info.bit_num, 'int8');
    train_info.use_data_weight=false;
end

run_converge=false;
update_bit=0;

while ~run_converge
   
   
   update_bit=update_bit+1;
     
   
   work_info_step1.update_bi_code=[];
   work_info_step2.update_bi_code_step1=[];
      
   
   work_info_step1.update_bit=update_bit;
     
   
   if ~train_info.train_stagewise
       work_info_step1.update_bit_loss=train_info.bit_num;
   else
       work_info_step1.update_bit_loss=update_bit;
   end
   
   if update_bit>1
       pre_bi_code=work_info_step2.update_bi_code_step2;
       assert(~isempty(pre_bi_code));
       one_hamm_dist_pairs=calc_hamm_dist_r_map(pre_bi_code, work_info_step1.relation_map);
       init_hamm_dist_pairs0=work_info_step1.init_hamm_dist_pairs0;
       init_hamm_dist_pairs0=init_hamm_dist_pairs0+one_hamm_dist_pairs;
       work_info_step1.init_hamm_dist_pairs0=init_hamm_dist_pairs0;
   end
       
      
   t1=tic;
   work_info_step1=train_step1(train_info, work_info_step1);
   time_info.one_time_step1=toc(t1);
   time_info.time_step1=time_info.time_step1+time_info.one_time_step1;
      

   disp_loop_info_step1(train_info, work_info_step1, time_info);

   
   work_info_step2.update_bi_code_step2=[];
   assert(~isempty(work_info_step1.update_bi_code));
      
   if ~train_info.train_stagewise
       
       bi_code_bits(:, update_bit)=work_info_step1.update_bi_code;
       work_info_step2.update_bi_code_step2=work_info_step1.update_bi_code;
       
   else
       work_info_step2.update_bit=update_bit;
       work_info_step2.data_weights=work_info_step1.data_weights;
       
       work_info_step2.update_bi_code_step1=work_info_step1.update_bi_code;
       
       t3_tic=tic;
       work_info_step2=train_step2(train_info, train_data, work_info_step2);
       t3=toc(t3_tic);
       time_info.one_time_step2=t3;
       time_info.time_step2=time_info.time_step2+t3;
       disp_loop_info_step2(train_info, work_info_step2, time_info); 
   end
   
    if update_bit>=train_info.bit_num
        run_converge=true;
    end
    
    
    one_method_time=toc(time_info.method_time_tic);
    time_info.method_time_bits(update_bit)=one_method_time;
    
end


if ~train_info.train_stagewise
    
    for b_idx=1:train_info.bit_num
        
        work_info_step2.update_bit=b_idx;
        work_info_step2.data_weights=[];
        work_info_step2.update_bi_code_step1=bi_code_bits(:,b_idx);
        
        t3_tic=tic;
        work_info_step2=train_step2(train_info, train_data, work_info_step2);
        t3=toc(t3_tic);
        time_info.one_time_step2=t3;
        time_info.time_step2=time_info.time_step2+t3;
        disp_loop_info_step2(train_info, work_info_step2, time_info); 
        
        
        time_info.method_time_bits(b_idx)=time_info.method_time_bits(b_idx)+t3;
        
    end
    
end


end






function train_result=gen_train_result(train_info, work_info_step1, work_info_step2, time_info)

train_result=[];

hash_learner_infos=work_info_step2.hash_learner_infos;
hash_learners=clean_hash_learners(hash_learner_infos);


hash_learners_model=work_info_step2.hash_learners_model;
if isfield(hash_learners_model, 'post_process_fn')
    [hash_learners, hash_learners_model]=...
        hash_learners_model.post_process_fn(hash_learners, hash_learners_model);
    hash_learners_model.post_process_fn=[];
end


model=[];
model.hs=hash_learners;
model.hs_model=hash_learners_model;
train_result.model=model;

train_result.obj_value=work_info_step1.obj_value;

train_result.time_info=time_info;
train_result.train_id=train_info.train_id;


end




function hash_learners=clean_hash_learners(hash_learner_infos)


bit_num=size(hash_learner_infos,1);
hash_learners=cell(bit_num,1);

for b_idx=1:bit_num
    hash_learners(b_idx,:)=hash_learner_infos{b_idx}.hash_learner;
end


end







function work_info_step1=gen_work_info_step1(relation_info)

work_info_step1=[];

gen_param=[];
gen_param.relation_info=relation_info;
gen_result=gen_relation_map(gen_param);

work_info_step1.relation_map=gen_result.relation_map;
work_info_step1.relevant_sel=gen_result.relevant_sel;

work_info_step1.init_hamm_dist_pairs0=zeros(length(work_info_step1.relevant_sel), 1);

end









function hamm_dist_pairs=calc_hamm_dist_r_map(bi_code, relation_map)


    e_bi_code=bi_code(relation_map(:,1),:);
    right_bi_code=bi_code(relation_map(:,2),:);
        
    hamm_dist_pairs=sum(e_bi_code~=right_bi_code, 2);
    
end





function disp_loop_info_step1(train_info, work_info_step1, time_info)


time_info.method_time=toc(time_info.method_time_tic);
fprintf('\n---Step-1, train_id:%s, loss:%s, infer:%s, sw:%d, total_time(sec):%.0f(%.1fh), obj:%.4f, update_bit:%d/%d\n', ...
 	train_info.train_id, train_info.hash_loss_type, train_info.binary_infer_method, train_info.train_stagewise, ...
    time_info.method_time, (time_info.method_time/3600), ...
 	work_info_step1.obj_value, work_info_step1.update_bit, train_info.bit_num);

end



function disp_loop_info_step2(train_info, work_info_step2, time_info)

update_bit=work_info_step2.update_bit;
one_hash_learner_info=work_info_step2.hash_learner_infos{update_bit};

time_info.method_time=toc(time_info.method_time_tic);
fprintf('---Step-2, classifier:%s, accuracy:(%.2f, weight:%.2f), update_bit:%d/%d \n', ...
 	train_info.hash_learner_param.classifier_type, ...
 	one_hash_learner_info.acc, one_hash_learner_info.acc_weight, work_info_step2.update_bit, train_info.bit_num);


end







