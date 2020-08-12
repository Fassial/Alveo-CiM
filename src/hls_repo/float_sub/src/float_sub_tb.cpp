#include<iostream>
#include<iomanip>
#include "float_sub.h"

using namespace std;

int main() {
    data_t A = 0.125;
    data_t B = 9.12512;
    data_t C = 0;
    data_t ref_C = -9.00012;

    C = float_sub(A, B);
    if (C != ref_C) {
        cout << "Test Failed!" << "\n";
        return 1;
    } else {
        cout << "Test Pass!" << "\n";
        return 0;
    }
}
