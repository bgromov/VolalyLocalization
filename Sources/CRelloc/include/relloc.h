//
//  relloc.h
//  
//
//  Created by Boris Gromov on 23.07.2020.
//  


#ifndef relloc_h
#define relloc_h

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

double estimate_pose(size_t count, const double p[], const double qc[3], const double qv[], double (*x)[4]);

#ifdef __cplusplus
}
#endif


#endif /* relloc_h */
