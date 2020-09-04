

function relation_info=gen_relation_info(affinity_labels)


e_num=size(affinity_labels, 1);


rel_mat=affinity_labels>0;
irrel_mat=affinity_labels<0;

rel_mat=rel_mat|rel_mat';
irrel_mat=irrel_mat|irrel_mat';



relation_info=[];
relation_info.rel_mat=rel_mat;
relation_info.irrel_mat=irrel_mat;
relation_info.e_num=e_num;


relation_info.get_rel_idxes_fn=@get_rel_idxes;
relation_info.get_irrel_idxes_fn=@get_irrel_idxes;


end






function rel_idxes=get_rel_idxes(relation_info, e_idx)

one_rel=relation_info.rel_mat(:, e_idx);
rel_idxes=find(one_rel);

end


function irrel_idxes=get_irrel_idxes(relation_info, e_idx)

irrel_mat=relation_info.irrel_mat;
if isempty(irrel_mat)
    one_rel=relation_info.rel_mat(:, e_idx);
    one_rel(e_idx)=false;
    irrel_idxes=find(~one_rel);
else
    irrel_idxes=find(irrel_mat(:, e_idx));
end

end





