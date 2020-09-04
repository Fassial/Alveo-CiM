



function gen_result=gen_relation_map(gen_param)
                
    gen_result=gen_relation_map_duplet(gen_param);
    assert(isa(gen_result.relation_map, 'uint32'));
        
end





function gen_result=gen_relation_map_duplet_simple(gen_param)

relation_info=gen_param.relation_info;



rel_mat=relation_info.rel_mat;
sel_rel_mat=rel_mat;
[r2_org r1]=find(sel_rel_mat);
r2_org=uint32(r2_org);
r1=uint32(r1);

valid_e_num=size(rel_mat, 1);


rel_r_num=length(r1);


irrel_mat=relation_info.irrel_mat;
if ~isempty(irrel_mat)
    sel_rel_mat=irrel_mat;
    [irsel_r2_org irsel_r1]=find(sel_rel_mat);

else
    irsel_r1=cell(valid_e_num,1);
    irsel_r2_org=cell(valid_e_num,1);
    for e_idx_idx=1:valid_e_num
        e_idx=e_idx_idx;
        n_top_knn_inds=relation_info.get_irrel_idxes_fn(e_idx);
        one_irsel_r2_org=uint32(n_top_knn_inds);
        one_irsel_r1=repmat(uint32(e_idx), one_r_num, 1);
        irsel_r2_org{e_idx_idx}=one_irsel_r2_org;
        irsel_r1{e_idx_idx}=one_irsel_r1;
    end
    irsel_r1=cell2mat(irsel_r1);
    irsel_r2_org=cell2mat(irsel_r2_org);
end
irrel_r_num=length(irsel_r1);


assert(rel_r_num>0 || irrel_r_num);

r1=cat(1, r1, irsel_r1);
r1_org=r1;
r2_org=cat(1, r2_org, irsel_r2_org);
r_num=rel_r_num+irrel_r_num;
relation_map=cat(2, r1_org, r2_org);
relevant_sel=false(r_num, 1);
relevant_sel(1:rel_r_num)=true;


assert(r_num<2^32);

gen_result=[];
gen_result.relation_map=relation_map;
gen_result.relevant_sel=relevant_sel;
gen_result.r1_new=r1;


end





function gen_result=gen_relation_map_duplet(gen_param)


gen_result_simple=gen_relation_map_duplet_simple(gen_param);
relation_map=gen_result_simple.relation_map;
relevant_sel=gen_result_simple.relevant_sel;
r1=gen_result_simple.r1_new;

r1_org=relation_map(:,1);
r2_org=relation_map(:,2);

r_num=length(r1);

valid_r_sel=r1_org<r2_org;
expect_r_num=r_num/2;


relation_map=relation_map(valid_r_sel,:);
relevant_sel=relevant_sel(valid_r_sel,:);


assert(size(relation_map,1)==expect_r_num);

gen_result=[];
gen_result.relation_map=relation_map;
gen_result.relevant_sel=relevant_sel;


end





