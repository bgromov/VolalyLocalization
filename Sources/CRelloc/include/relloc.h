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

#define GRADIENT_NORM   (0)
#define OBJECTIVE_DELTA (1)

typedef struct {
    uint8_t verbose;
    uint8_t stop_strategy;
    double stop_threshold;
    unsigned long max_iter;
} options_t;

double estimate_pose(size_t count, const double p[], const double qc[3], const double qv[], double x[4], const options_t* options);

#ifdef __cplusplus
}
#endif


#endif /* relloc_h */
