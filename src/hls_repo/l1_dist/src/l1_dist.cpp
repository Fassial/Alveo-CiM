#include<math.h>
#include "l1_dist.h"

data_t l1_dist(data_t A[N], data_t B[N]) {
    data_t dist_1 = 0;
    data_t C[N];
    // calculate sub
    l1_dist_loop1:for (int i = 0; i < N; i+=1) {
        data_t diff;
        diff = fabs(A[i] - B[i]);
        C[i] = diff;
    }
    l1_dist_loop2:for (int i = 0; i < N; i++) {
        dist_1 += C[i];
    }
    // return res
    return dist_1;
}
