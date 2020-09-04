function model = LSH_learn(X, maxbits)

hs = normrnd(0, 1, size(X, 2), maxbits);
model.hs = hs;


end
