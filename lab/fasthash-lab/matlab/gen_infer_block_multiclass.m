



function infer_info=gen_infer_block_multiclass(label_data)

   fprintf('\n------------- gen_infer_block_multiclass... \n')
   
   assert(size(label_data, 2)==1);
   
   e_num=size(label_data,1);
   [label_vs, ~, new_y]=unique(label_data);
   label_map=false(e_num, length(label_vs));
   tmp_idxes=sub2ind(size(label_map), 1:e_num, new_y');
   label_map(tmp_idxes)=true;

        
    relevant_groups=[];

    if isempty(relevant_groups)
        relevant_groups=gen_relevant_groups_predifined(label_map);
    end
            
    assert(~isempty(relevant_groups));
       

    fprintf('\n------------- gen_infer_block_multiclass finished \n')


    infer_info.infer_groups=relevant_groups;


end







function relevant_groups=gen_relevant_groups_predifined(group_map)

g_num=size(group_map, 2);
relevant_groups=cell(g_num, 1);
valid_sel=false(g_num, 1);
for g_idx=1:g_num
    one_group_idxes=find(group_map(:, g_idx));
    if ~isempty(one_group_idxes)
        relevant_groups{g_idx}=one_group_idxes;
        valid_sel(g_idx)=true;
    end
end

relevant_groups=relevant_groups(valid_sel);


end




