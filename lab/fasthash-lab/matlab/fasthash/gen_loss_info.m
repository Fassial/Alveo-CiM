

function cache_info=gen_loss_info(train_info, cache_info)



loss_type=train_info.hash_loss_type;


if strcmp(loss_type, 'KSH')
    clac_loss_paris_fn=@clac_loss_paris_KSH;
    gen_cache_fn=@gen_cache_KSH;
end

if strcmp(loss_type, 'BRE')
    clac_loss_paris_fn=@clac_loss_paris_BRE;
    gen_cache_fn=@gen_cache_BRE;
end

if strcmp(loss_type, 'Hinge')
    clac_loss_paris_fn=@clac_loss_paris_Hinge;
    gen_cache_fn=@gen_cache_Hinge;
end



cache_info.clac_loss_paris_fn=clac_loss_paris_fn;
cache_info.gen_pair_weights_fn=@gen_pair_weights;
cache_info=gen_cache_fn(train_info, cache_info);

end



function [pair_weights dist0_loss_items dist1_loss_items]=...
    gen_pair_weights(train_info, cache_info, init_hamm_dist_pairs0, loss_bit_num)


	clac_loss_paris_fn=cache_info.clac_loss_paris_fn;
    
        
    one_hamm_dist_pairs=init_hamm_dist_pairs0;
    dist0_loss_items=clac_loss_paris_fn(train_info, cache_info, one_hamm_dist_pairs, loss_bit_num);
    
    one_hamm_dist_pairs=init_hamm_dist_pairs0+1;
    dist1_loss_items=clac_loss_paris_fn(train_info, cache_info, one_hamm_dist_pairs, loss_bit_num);
    
    pair_weights=dist0_loss_items-dist1_loss_items;    
       
end





function loss_pairs=clac_loss_paris_BRE(train_info, cache_info, hamm_dist_pairs, bit_num)


gt_hdist_norm_pairs=cache_info.gt_hdist_norm_pairs;
loss_pairs=(gt_hdist_norm_pairs-hamm_dist_pairs./bit_num);

loss_pairs=loss_pairs.^2;


end


function cache_info=gen_cache_BRE(train_info, cache_info)


relevant_sel=cache_info.relevant_sel;
gt_hdist_norm_pairs=double(~relevant_sel);



cache_info.gt_hdist_norm_pairs=gt_hdist_norm_pairs;

  
end




function loss_pairs=clac_loss_paris_KSH(train_info, cache_info, hamm_dist_pairs, bit_num)


hamm_aff_pairs=bit_num - 2.*hamm_dist_pairs;


gt_haff_norm_pairs=cache_info.gt_haff_norm_pairs;
loss_pairs=(gt_haff_norm_pairs-hamm_aff_pairs./bit_num);

loss_pairs=loss_pairs.^2;


end


function cache_info=gen_cache_KSH(train_info, cache_info)


relevant_sel=cache_info.relevant_sel;
gt_haff_norm_pairs=ones(length(relevant_sel), 1);
gt_haff_norm_pairs(~relevant_sel)=-1;


cache_info.gt_haff_norm_pairs=gt_haff_norm_pairs;

  
end






function loss_pairs=clac_loss_paris_Hinge(train_info, cache_info, hamm_dist_pairs, bit_num)




gt_hdist_norm_pairs=cache_info.gt_hdist_norm_pairs;
loss_pairs=(gt_hdist_norm_pairs-hamm_dist_pairs./bit_num);

relevant_sel=cache_info.relevant_sel;
loss_pairs(relevant_sel)=-loss_pairs(relevant_sel);

% hinge here:
loss_pairs=max(loss_pairs, 0);

loss_pairs=loss_pairs.^2;

end








function cache_info=gen_cache_Hinge(train_info, cache_info)

% or change this setting
    
hdist_pos_ratio=0.0;
hdist_neg_ratio=0.5;

assert(hdist_pos_ratio<hdist_neg_ratio);
   

relevant_sel=cache_info.relevant_sel;
gt_hdist_norm_pairs=ones(size(relevant_sel));
gt_hdist_norm_pairs(relevant_sel)=hdist_pos_ratio;
gt_hdist_norm_pairs(~relevant_sel)=hdist_neg_ratio;

cache_info.gt_hdist_norm_pairs=gt_hdist_norm_pairs;

  
end





