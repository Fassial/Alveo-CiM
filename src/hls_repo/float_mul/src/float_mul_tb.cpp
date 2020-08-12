#include<iostream>
#include<iomanip>
#include "float_mul.h"

using namespace std;

int main() {
    data_t A = 0.125;
    data_t B = 9.12512;
    data_t C = 0;
    data_t ref_C = 1.14064;

    C = float_mul(A, B);
    if (C != ref_C) {
        cout << "Test Failed!" << "\n";
        return 1;
    } else {
        cout << "Test Pass!" << "\n";
        return 0;
    }
}
