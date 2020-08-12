#include "faddn.h"

data_t faddn(data_t A[N]) {
    data_t sum = 0;
    faddn_loop1:for (int i = 0; i < N; i++) {
        sum += A[i];
    }
    return sum;
}
