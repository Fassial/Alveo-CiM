



function infer_info=gen_infer_block(relation_info)

fprintf('\n------------- gen_infer_block... \n')
    
    
    relevant_groups=[];
        
    if isempty(relevant_groups)
        relevant_groups=gen_relevant_groups(relation_info);
    end
    
    assert(~isempty(relevant_groups));
    

fprintf('\n------------- gen_infer_block finished \n')


infer_info.infer_groups=relevant_groups;


end








function relevant_groups=gen_relevant_groups(relation_info)

e_num=relation_info.e_num;
relevant_groups=cell(0,1);
can_sel=true(e_num,1);

fprintf('--gen_relevant_groups:\n');


disp_step=0.05;
disp_thresh=disp_step;
finish_rate=0;



while finish_rate<1
    
            
    group_e_idxes=gen_one_group(relation_info, can_sel);
    can_sel(group_e_idxes)=false;
    
    relevant_groups=cat(1, relevant_groups, {group_e_idxes});
    
    finish_rate=(e_num-nnz(can_sel))/e_num;
    if finish_rate>=disp_thresh
        fprintf(' %.2f ', finish_rate);
        disp_thresh=disp_thresh+disp_step;
    end
    
end    

fprintf(' <--done!\n');

end



function group_e_idxes=gen_one_group(relation_info, can_sel)

group_e_sel=false(length(can_sel), 1);

can_e_idxes=find(can_sel);
root_e_idx=can_e_idxes(randsample(length(can_e_idxes), 1));


group_e_sel(root_e_idx)=true;
can_sel(root_e_idx)=false;



rel_e_idxes=relation_info.get_rel_idxes_fn(relation_info, root_e_idx);
can_sel(rel_e_idxes)=false;



can_e_idxes=find(can_sel);
can_e_idxes=can_e_idxes(randperm(length(can_e_idxes)));


can_e_idxes=cat(1, rel_e_idxes, can_e_idxes);


for g_idx=1:length(can_e_idxes)
    
    other_e_idx=can_e_idxes(g_idx);
    
    is_valid=check_consistent(relation_info, group_e_sel, other_e_idx);
    if is_valid
        group_e_sel(other_e_idx)=true;
    end
    
end

group_e_idxes=find(group_e_sel);


end



function is_valid=check_consistent(relation_info, group_e_sel, e_idx)



irrel_idxes=relation_info.get_irrel_idxes_fn(relation_info, e_idx);
check_sel=group_e_sel(irrel_idxes);
is_valid=~any(check_sel);

end



