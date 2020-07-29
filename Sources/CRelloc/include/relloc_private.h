//
//  relloc_private.h
//
//
//  Created by Boris Gromov on 28.07.2020.
//


#ifndef relloc_private_h
#define relloc_private_h

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

double angle_between(const double v1[], const double v2[]);
void transform_points(size_t count, const double points[], const double tf[4], double* output);
void error_function(size_t count, const double p[], const double qc[], const double qv[], const double x[4], double* err);

#ifdef __cplusplus
}
#endif


#endif /* relloc_private_h */
