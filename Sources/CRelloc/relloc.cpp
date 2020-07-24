//
//  File.cpp
//  
//
//  Created by Boris Gromov on 23.07.2020.
//  

#include <dlib/optimization.h>
#include <dlib/global_optimization.h>
#include <iostream>
#include <algorithm>

#include "relloc.h"

// Use (void) to silent unused warnings.
#define assertm(exp, msg) assert(((void)msg, exp))

using namespace std;
using namespace dlib;

// ----------------------------------------------------------------------------------------

namespace relloc {
    typedef matrix<double, 0, 1> column_vector; // tx, ty, tz, and rotz

    typedef dlib::vector<double, 3> point3d;
    typedef dlib::vector<double, 3> vector3d;
    typedef point_transform_affine3d ray;

    point_transform_affine3d make_transform(double tx, double ty, double tz, double rotz)
    {
        return point_transform_affine3d(rotate_around_z(rotz).get_m(), translate_point(tx, ty, tz).get_b());
    }

    std::vector<point3d> transform_points(const std::vector<point3d>& points, const point_transform_affine3d& tf)
    {
        std::vector<point3d> res;

        res.reserve(points.size());

        std::transform(points.begin(), points.end(), std::back_inserter(res),
            [tf](point3d pt) -> point3d
            {
                return tf(pt);
            });

        return res;
    }

    double angle_between(const vector3d& v1, const vector3d& v2)
    {
        vector3d v1_u = dlib::normalize(v1);
        vector3d v2_u = dlib::normalize(v2);

        return std::acos(std::clamp(dot(v1_u, v2_u), -1.0, 1.0));
    }

    std::vector<double> error_function(const std::vector<point3d>& points, const point3d& qc, const std::vector<vector3d>& qv, const column_vector& m)
    {
        const double tx   = m(0);
        const double ty   = m(1);
        const double tz   = m(2);
        const double rotz = m(3);

        point_transform_affine3d tf = make_transform(tx, ty, tz, rotz);
        std::vector<point3d> tp = transform_points(points, tf);

        std::vector<double> err;
        std::transform(tp.begin(), tp.end(), qv.begin(), std::back_inserter(err),
            [&](const point3d& pt, const vector3d& r) -> double
            {
    //            vector3d x(1.0, 0.0, 0.0);
    //            point3d  r = ray_tf(x);
                return angle_between(r, pt - qc);
            });

        return err;
    }

    double estimate_pose(const std::vector<point3d>& points, const point3d& qc, const std::vector<vector3d>& qv, column_vector& m, bool verbose = false)
    {
        double residual;

        auto mean_err = [&](const column_vector& cur_estimate) -> double
        {
            column_vector pos = {cur_estimate(0), cur_estimate(1), cur_estimate(2)};

            return dlib::mean(dlib::mat(error_function(points, qc, qv, cur_estimate))) + std::max(0.0, dlib::length(pos) - 7.0);
        };

        auto stop_strategy = gradient_norm_stop_strategy(1e-5, 100);
//        auto stop_strategy = objective_delta_stop_strategy(1e-9);

        if (verbose) stop_strategy.be_verbose();

        return find_min_using_approximate_derivatives(bfgs_search_strategy(),
                                                      stop_strategy,
                                                      mean_err, m, -1,
                                                      1.4901161193847656e-08);

//        auto res = find_min_global(mean_err,
//                                   {-10.0, -10.0, -10.0, -M_PI},
//                                   { 10.0,  10.0,  10.0,  M_PI},
//                                   std::chrono::milliseconds(5000));
//
//        m = res.x;
//
//        return res.y;
    }
}

void print_array(std::string msg, const double a[], size_t len)
{
    printf("%s", msg.c_str());

    for (size_t i = 0; i < len; i++)
    {
        printf("%7.3f ", a[i]);
    }

    printf("\n");
}

#ifdef __cplusplus
extern "C" {
#endif

double estimate_pose(size_t count, const double p[], const double qc[3], const double qv[], double (*x)[4], int verbose_flag)
{
    std::vector<relloc::point3d> _p;
    std::vector<relloc::vector3d> _qv;
    relloc::column_vector _x = dlib::mat((*x), 4);
    relloc::point3d _qc(qc[0], qc[1], qc[2]);

    _p.reserve(count);
    _qv.reserve(count);

    for (size_t i = 0; i < 3 * count; i += 3)
    {
        _p.push_back(relloc::point3d(p[i], p[i+1], p[i+2]));
        _qv.push_back(relloc::vector3d(qv[i], qv[i+1], qv[i+2]));
    }

    if (verbose_flag)
    {
        print_array("p:\n", p, count * 3);
        print_array("qc:\n", qc, 3);
        print_array("qv:\n", qv, count * 3);
        print_array("x:\n", *x, 4);
    }

    double res = relloc::estimate_pose(_p, _qc, _qv, _x, (bool)verbose_flag);

    memcpy(x, &(_x.steal_memory()[0]), sizeof(*x));

    if (verbose_flag)
    {
        print_array("new x:\n", *x, 4);
    }

    return res;
}

#ifdef __cplusplus
}
#endif

