/*
 * l1_dist.h
 *
 *  Created on: August 13, 2020
 *      Author: fassial
 */

#ifndef L1_DIST_H_
#define L1_DIST_H_

// def macro
#define N 1024/16

// def struct
typedef float data_t;

// def funcs
data_t l1_dist(data_t A[N], data_t B[N]);

#endif /* L1_DIST_H_ */
