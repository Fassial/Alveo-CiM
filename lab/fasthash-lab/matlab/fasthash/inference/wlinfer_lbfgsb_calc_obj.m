
function objfv=wlinfer_lbfgsb_calc_obj(w, aux_data)

conn_map=aux_data{1};

e_num=length(w);
objfv2=w'*conn_map*w;
objfv2=objfv2./e_num;

objfv=objfv2;

end
