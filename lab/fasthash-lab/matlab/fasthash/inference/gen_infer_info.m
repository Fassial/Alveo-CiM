

function infer_info=gen_infer_info(train_info, work_info_step1)
    
    infer_info=[];
    infer_info.relation_weights=[];
    infer_info.relation_map=work_info_step1.relation_map; 
    infer_info.single_weights=[];
    
    infer_info.e_num=train_info.e_num;
    
    infer_info.infer_cache=gen_infer_cache(train_info, infer_info);
   
    
    if train_info.do_infer_spectral
        infer_info.relation_map=double(infer_info.relation_map);
    end

end




function infer_cache=gen_infer_cache(train_info, infer_info)



infer_cache=[];

if train_info.do_infer_block
    infer_cache=gen_infer_cache_block(train_info, infer_info, infer_cache);
end


end





function infer_cache=gen_infer_cache_block(train_info, infer_info, infer_cache)


infer_groups=train_info.infer_info.infer_groups;
group_num=length(infer_groups);

relation_map=infer_info.relation_map;
r1_org_global=relation_map(:, 1);
r2_org_global=relation_map(:, 2);

trans_map=zeros(infer_info.e_num, 1, 'uint32');

assert(length(r1_org_global)<2.^31);


shared_task_data=[];
shared_task_data.r1_org_global=r1_org_global;
shared_task_data.r2_org_global=r2_org_global;
shared_task_data.trans_map=trans_map;
shared_task_data.infer_groups=infer_groups;


if ~isfield(train_info, 'use_mmat')
    train_info.use_mmat=false;
end

if train_info.use_mmat

    task_inputs=num2cell((1:group_num)', 2);
    task_num=length(task_inputs);

    mmat=train_info.mmat;
    runner_change_path(mmat, pwd);
        
    task_helper=create_task_helper(mmat, task_num);
    task_helper.set_callback_run_task_func(task_helper, @do_one_task_gen_infer_cache_func);
    task_helper.set_task_data(task_helper, task_inputs, shared_task_data);
    task_helper.run_tasks(task_helper);
    infer_info_groups=task_helper.get_task_results(task_helper);


else

    infer_info_groups=cell(group_num, 1);

    for g_idx=1:group_num
                
        one_infer_info=do_one_task_gen_infer_cache(g_idx, shared_task_data);        
        
        infer_info_groups{g_idx}=one_infer_info;
    end

end

infer_cache.infer_info_groups=infer_info_groups;


end


function [task_result shared_task_data]=do_one_task_gen_infer_cache_func(task_input, shared_task_data, runner_info, task_index)

    task_result=do_one_task_gen_infer_cache(task_input, shared_task_data);

end





function one_infer_info=do_one_task_gen_infer_cache(task_input, shared_task_data)

        g_idx=task_input;


        r1_org_global=shared_task_data.r1_org_global;
        r2_org_global=shared_task_data.r2_org_global;
        trans_map=shared_task_data.trans_map;
        infer_groups=shared_task_data.infer_groups;




        sel_e_idxes=infer_groups{g_idx};
        sel_e_idxes=uint32(sel_e_idxes);
           
        r1_sel=ismember(r1_org_global, sel_e_idxes);
        r2_sel=ismember(r2_org_global, sel_e_idxes);
        
        r_sel=r1_sel|r2_sel;
        r1=r1_org_global(r_sel);
        r2=r2_org_global(r_sel);
        r1_sel=r1_sel(r_sel);
        r2_sel=r2_sel(r_sel);
        
        sel_r_idxes=uint32(find(r_sel));
        
        exchange_sel=~r1_sel;
        tmp_r1=r1(exchange_sel);
        r1(exchange_sel)=r2(exchange_sel);
        r2(exchange_sel)=tmp_r1;
        r2_sel(exchange_sel)=false;
        multual_sel=r2_sel;
                
        trans_map(sel_e_idxes)=1:length(sel_e_idxes);
            
        r2_org=r2;
        r1=trans_map(r1);
        sel_r1=r1(multual_sel);
        sel_r2=r2(multual_sel);
        sel_r2=trans_map(sel_r2);
                       
            
        sample_info=[];
        sample_info.multual_sel=multual_sel;

        non_sel1=~multual_sel;
        sample_info.non_sel1=non_sel1;
        sample_info.non_sel2=[];
        sample_info.non_sel1_e_idxes=r1(non_sel1);
        sample_info.non_sel1_e_idxes_other=r2_org(non_sel1);
        sample_info.non_sel2_e_idxes=[];
        sample_info.non_sel2_e_idxes_other=[];
        
        sample_info.sample_e_num=length(sel_e_idxes);
        sample_info.sel_r_idxes=sel_r_idxes;
        
        one_relation_map=cat(2, sel_r1, sel_r2);
        assert(isa(one_relation_map, 'uint32'));
        
            
        one_infer_info=[];
        one_infer_info.sample_info=sample_info;
        one_infer_info.sel_e_idxes=sel_e_idxes;
        one_infer_info.e_num=length(sel_e_idxes);
        one_infer_info.relation_map=one_relation_map;


end






