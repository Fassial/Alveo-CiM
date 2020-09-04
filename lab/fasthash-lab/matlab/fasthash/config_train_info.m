

function train_info=config_train_info(train_info)


% check parameter settings...

    
if ~isfield(train_info, 'hash_loss_type')
    train_info.hash_loss_type='KSH';
    % train_info.hash_loss_type='BRE';
    % train_info.hash_loss_type='Hinge';
end


if ~isfield(train_info, 'train_stagewise')
    train_info.train_stagewise=true;
end



if ~isfield(train_info, 'binary_infer_method')
	train_info.binary_infer_method='block_graphcut';
	% train_info.binary_infer_method='spectral';
end


train_info.do_infer_spectral=false;
train_info.do_infer_block=false;

if strcmp(train_info.binary_infer_method, 'block_graphcut')
	train_info.do_infer_block=true;
    train_info.infer_block_type='graphcut';
end

if strcmp(train_info.binary_infer_method, 'spectral')
	train_info.do_infer_spectral=true;
end





end



