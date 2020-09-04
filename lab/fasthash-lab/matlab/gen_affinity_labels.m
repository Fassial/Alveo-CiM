


% generate pairwise affinity ground truth for supervised hashing learning:
% a simple example is shown here for dataset with multi-class labels.
% users can replace this ground truth definition here according to your applications.

function affinity_labels=gen_affinity_labels(train_data)


disp('gen_affinity_labels...');

e_num=size(train_data.feat_data, 1);
label_data=train_data.label_data;
assert(size(label_data, 1)==e_num);
assert(size(label_data, 2)==1);



affinity_labels=zeros(e_num, e_num, 'int8');

max_similar_num=100;
max_dissimilar_num=100;

for e_idx=1:e_num
	relevant_sel=label_data(e_idx)==label_data;
	irrelevant_sel=~relevant_sel;
	relevant_sel(e_idx)=false;

	relevant_idxes=find(relevant_sel);
	if length(relevant_idxes)>max_similar_num
		relevant_idxes=relevant_idxes(randsample(length(relevant_idxes), max_similar_num));
	end

	irrelevant_idxes=find(irrelevant_sel);
	if length(irrelevant_idxes)>max_dissimilar_num
		irrelevant_idxes=irrelevant_idxes(randsample(length(irrelevant_idxes), max_dissimilar_num));
	end

	affinity_labels(e_idx, relevant_idxes)=1;
	affinity_labels(e_idx, irrelevant_idxes)=-1;

	% make it symmetric:
	affinity_labels(relevant_idxes, e_idx)=1;
	affinity_labels(irrelevant_idxes, e_idx)=-1;

	% make the diagonal to 0
	affinity_labels(e_idx, e_idx)=0;


end


end