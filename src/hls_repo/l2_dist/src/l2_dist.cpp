#include "l2_dist.h"

data_t l2_dist(data_t A[N], data_t B[N]) {
    data_t dist_2 = 0;
    data_t C[N];
    // calculate sub
    l2_dist_loop1:for (int i = 0; i < N; i+=1) {
        data_t diff, diff_2;
        diff = (A[i] - B[i]);
        diff_2 = diff * diff;
        C[i] = diff_2;
    }
    l2_dist_loop2:for (int i = 0; i < N; i++) {
        dist_2 += C[i];
    }
    // return res
    return dist_2;
}
