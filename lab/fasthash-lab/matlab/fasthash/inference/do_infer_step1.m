





function infer_result=do_infer_step1(train_info, infer_info)

% turn this on for debug
infer_calc_obj=false;


init_bi_code=infer_info.init_bi_code;

init_infer_result=[];
init_infer_result.infer_bi_code=init_bi_code;

if infer_calc_obj
    obj_init=calc_infer_obj(init_bi_code, infer_info);
    init_infer_result.obj_value=obj_init;
end

infer_result=[];

if train_info.do_infer_spectral
    infer_result=do_infer_spectral(train_info, infer_info, init_infer_result);
end


if train_info.do_infer_block
    infer_result=do_infer_block(train_info, infer_info, init_infer_result);
end




assert(~isempty(infer_result));


infer_result.obj_reduced=NaN;

if infer_calc_obj
    
    if ~isfield(infer_result, 'obj_value')
        infer_result.obj_value=calc_infer_obj(infer_result.infer_bi_code, infer_info);
    end
    infer_result.obj_reduced=obj_init - infer_result.obj_value;
    
    % when debug
    % assert(infer_result.reduced_obj>=-1e-6);
end


bi_code=infer_result.infer_bi_code;
assert(size(bi_code,2)==1);
assert(size(bi_code,1)==train_info.e_num);
assert(isa(bi_code, 'int8'));



end








function [obj_value]=calc_infer_obj(bi_code, infer_info)

assert(length(bi_code)==infer_info.e_num);

relation_map=infer_info.relation_map;
relation_weights=infer_info.relation_weights;

relation_aff=calc_hamm_affinity(bi_code, relation_map);

obj_value=sum(relation_aff.*relation_weights);

if ~isempty(infer_info.single_weights)
    obj_value=obj_value+sum(infer_info.single_weights.*double(bi_code));
end


end





function infer_result=gen_infer_result(infer_name, infer_bi_code)


infer_result=[];
infer_result.infer_name=infer_name;
infer_result.infer_bi_code=int8(infer_bi_code);


end




function infer_info=update_infer_info_spectral(train_info, infer_info)

assert(length(infer_info.relation_weights)==size(infer_info.relation_map,1));

relation_map=infer_info.relation_map;
relation_weights=infer_info.relation_weights;
e_num=train_info.e_num;


if train_info.do_infer_spectral 
    

    if ~isempty(infer_info.single_weights)
       
        error('not support!');
       
    end
    
    weight_mat = sparse(relation_map(:,1),relation_map(:,2),relation_weights,e_num,e_num);
    infer_info.weight_mat=weight_mat;

    assert(sum(diag(weight_mat))==0);
    
  
   infer_info.weight_mat_symm=weight_mat+weight_mat';

end

end




function infer_result=do_infer_spectral(train_info, infer_info, init_infer_result)


infer_info=update_infer_info_spectral(train_info, infer_info);
weight_mat_symetric=infer_info.weight_mat_symm;

[eig_vectors, eig_values]=eigs(weight_mat_symetric,1,'sa');
    
sel_eig_idx=1;
infer_vs=eig_vectors(:,sel_eig_idx);
infer_vs=infer_vs(1:infer_info.e_num);
    
%thresh=median(infer_vs);
thresh=0;
infer_bi_code=nonzerosign(infer_vs-thresh);
    
infer_result=gen_infer_result('spectral', infer_bi_code);
infer_result.obj_value=calc_infer_obj(infer_bi_code, infer_info);
infer_result=do_infer_lbfgs(train_info, infer_info, infer_result);


end




function infer_result=do_infer_lbfgs(train_info, infer_info, init_infer_result)


init_bi_code=init_infer_result.infer_bi_code;
obj_init=init_infer_result.obj_value;

assert(~isempty(init_bi_code));

aux_data=cell(0);
aux_data{1}=infer_info.weight_mat;


objFv_func_name='wlinfer_lbfgsb_calc_obj';
grad_func_name='wlinfer_lbfgsb_calc_grad';

lb_epsilon=1e-4;

weight_mat_variable_num=size(infer_info.weight_mat,1);
lb=-ones(weight_mat_variable_num,1);
ub=ones(weight_mat_variable_num,1);


maxiter=30;
infer_bi_code=init_bi_code;

obj_value=obj_init;


try
        
    init_sol=zeros(weight_mat_variable_num,1);
    init_sol(1:infer_info.e_num)=init_bi_code;

    infer_vs_lbfgs = lbfgsb(init_sol, lb, ub, objFv_func_name,...
        grad_func_name, aux_data, [], 'factr', lb_epsilon, 'maxiter', maxiter);

    infer_vs_lbfgs=infer_vs_lbfgs(1:infer_info.e_num);

%   thresh=median(infer_vs_lbfgs);
    thresh=0;
    infer_bi_code_lbfgs=nonzerosign(infer_vs_lbfgs-thresh);


    obj_value_lbfgs=calc_infer_obj(infer_bi_code_lbfgs, infer_info);

    if obj_value_lbfgs<obj_value-eps
        obj_value=obj_value_lbfgs;
        infer_bi_code=infer_bi_code_lbfgs;
    end

catch err_info

    disp(err_info);

	if isempty(strfind(err_info.message, 'convergence'))
        disp(err_info);
        dbstack;
        error('error!');
    end

%     fprintf('\n\n --------------- WARNING lbfgs solver failed, probably bad initialization ------------\n\n');

end


infer_result=gen_infer_result('lbfgs', infer_bi_code);
infer_result.obj_value=obj_value;


end

  






function sum_v=idxsum(values, idxes, value_num)

sum_v=accumarray(idxes,values);

if length(sum_v)<value_num
    sum_v(value_num)=0;
end

end



function [relation_weights single_weights]=gen_relation_weight_block(sample_info, relation_weights, init_bi_code)

    sample_e_num=sample_info.sample_e_num;
    relation_weights=relation_weights(sample_info.sel_r_idxes);

    non_sel_bi_code=init_bi_code(sample_info.non_sel1_e_idxes_other);
    
    non_sel_weights=relation_weights(sample_info.non_sel1).*double(non_sel_bi_code);
        
    sw_extra_weights=idxsum(non_sel_weights, sample_info.non_sel1_e_idxes, sample_e_num);
        
    if ~isempty(sample_info.non_sel2_e_idxes)
        non_sel_bi_code=init_bi_code(sample_info.non_sel2_e_idxes_other);
        non_sel_weights=relation_weights(sample_info.non_sel2).*double(non_sel_bi_code);
        sw_extra_weights2=idxsum(non_sel_weights, sample_info.non_sel2_e_idxes, sample_e_num);
        sw_extra_weights=sw_extra_weights+sw_extra_weights2;
    end
        
       
    single_weights=sw_extra_weights;    
    relation_weights=relation_weights(sample_info.multual_sel);
end   



function one_infer_info=update_infer_info_block(one_infer_info, infer_info, infer_bi_code)

relation_weights=infer_info.relation_weights;
[relation_weights single_weights]=gen_relation_weight_block(...
        one_infer_info.sample_info, relation_weights, infer_bi_code);

one_infer_info.relation_weights=relation_weights;
one_infer_info.single_weights=single_weights;
        


end



function infer_result=do_infer_graphcut(train_info, infer_info, init_infer_result)


e_num=infer_info.e_num;
relation_map=infer_info.relation_map;
relation_weights=infer_info.relation_weights;

% submodular condition:
if max(relation_weights)>eps
    % dbstack;
    % keyboard;

    fprintf('\n WARNING, submodularity is not satisfied...\n');
    relation_weights=min(relation_weights, 0);
end

if ~isa(relation_map,'double')
    relation_map=double(relation_map);
end

weight_mat_block = sparse(relation_map(:,1),relation_map(:,2), -relation_weights,e_num,e_num);


weight_mat_block=weight_mat_block+weight_mat_block';
%     assert(sum(diag(weight_mat_block))==0);





% e_num=infer_info.e_num;
single_weights=infer_info.single_weights';

assert(~isempty(single_weights));


unary = cat(1, zeros(1, e_num), single_weights);


label_pairwise_cost=ones(2,2);
label_pairwise_cost(1,1)=0;
label_pairwise_cost(2,2)=0;

conn_map=weight_mat_block;

init_label=zeros(1, e_num);
init_label(init_infer_result.infer_bi_code>0)=1;


if nnz(conn_map)>0
    labels = GCMex(init_label, single(unary), conn_map, single(label_pairwise_cost));
else
    [~, labels]=min(unary, [], 1);
    labels=labels-1;
end


infer_bi_code=ones(length(labels),1);
infer_bi_code(labels<1)=-1;
infer_bi_code=infer_bi_code(1:infer_info.e_num);

infer_result=[];
infer_result.infer_bi_code=infer_bi_code;

end





function infer_result=do_infer_block(train_info, infer_info, init_infer_result)


infer_block_type=train_info.infer_block_type;
one_infer_fn=[];


if strcmp(infer_block_type, 'graphcut')
    one_infer_fn=@do_infer_graphcut; 
end



assert(~isempty(one_infer_fn));

infer_iter_num=train_info.infer_iter_num;
infer_iter_counter=0;

infer_info_groups=infer_info.infer_cache.infer_info_groups;
group_num=length(infer_info_groups);

infer_bi_code=init_infer_result.infer_bi_code;

while true
    
    group_idxes=randperm(group_num);
            
    for g_idx_idx=1:group_num
        
        g_idx=group_idxes(g_idx_idx);

        one_infer_info=infer_info_groups{g_idx};
        one_infer_info=update_infer_info_block(one_infer_info, infer_info, infer_bi_code);
        
        one_init_infer_result=[];
        one_init_infer_result.infer_bi_code=infer_bi_code(one_infer_info.sel_e_idxes);
        
        one_infer_result=one_infer_fn(train_info, one_infer_info, one_init_infer_result);
        
        one_bi_code=one_infer_result.infer_bi_code;
        infer_bi_code(one_infer_info.sel_e_idxes)=one_bi_code;
    end
    
    infer_iter_counter=infer_iter_counter+1;
    if infer_iter_counter>=infer_iter_num
        break;
    end
end


infer_result=gen_infer_result(['block_' infer_block_type], infer_bi_code);

infer_result.infer_iter_num=infer_iter_num;

end






    
 

function relation_aff=calc_hamm_affinity(bi_code, relation_map)

relation_aff=ones(size(relation_map,1), 1);
not_identical_sel=bi_code(relation_map(:,1))~=bi_code(relation_map(:,2));
relation_aff(not_identical_sel)=-1;

end




