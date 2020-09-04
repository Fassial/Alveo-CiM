function grad=wlinfer_lbfgsb_calc_grad(w, aux_data)


conn_map=aux_data{1};

e_num=length(w);
grad=conn_map*w;
grad=grad./(e_num/2);


end
