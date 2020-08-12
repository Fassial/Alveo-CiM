#include<iostream>
#include<iomanip>
#include<math.h>
#include "l2_dist.h"

using namespace std;

int main() {
    data_t A[N] = {0};
    data_t B[N] = {0};
    for (int i = 0; i < N; i++) {
        A[i] = 1; B[i] = 1.1;
    }
    data_t C = 0;
    data_t ref_C = N * 0.01;

    C = l2_dist(A, B);
    if (abs(C - ref_C) > 1e-2) {
        cout << "Test Failed!" << "Got: " << C << "\n";
        return 1;
    } else {
        cout << "Test Pass!" << "\n";
        return 0;
    }
}
