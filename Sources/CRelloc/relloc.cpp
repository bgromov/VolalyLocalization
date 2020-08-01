//
//  relloc.cpp
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

    std::vector<double> error_function(const std::vector<point3d>& points, const std::vector<point3d>& qc, const std::vector<vector3d>& qv, const column_vector& m)
    {
        const double tx   = m(0);
        const double ty   = m(1);
        const double tz   = m(2);
        const double rotz = m(3);

        point_transform_affine3d tf = make_transform(tx, ty, tz, rotz);
        std::vector<point3d> tp = transform_points(points, tf);
        std::vector<point3d> new_ray;

        std::transform(tp.begin(), tp.end(), qc.begin(), std::back_insert_iterator(new_ray),
            [](const point3d& t, const point3d& q) -> const point3d
            {
                return t - q;
            });

        std::vector<double> err;
        std::transform(new_ray.begin(), new_ray.end(), qv.begin(), std::back_inserter(err),
            [&](const point3d& new_r, const vector3d& r) -> double
            {
                return angle_between(r, new_r);
            });

        return err;
    }

    double estimate_pose(const std::vector<point3d>& points, const std::vector<point3d>& qc, const std::vector<vector3d>& qv, column_vector& m, const options_t& options)
    {
        double residual;

        auto mean_err = [&](const column_vector& cur_estimate) -> double
        {
            column_vector pos = {cur_estimate(0), cur_estimate(1), cur_estimate(2)};

            return dlib::mean(dlib::mat(error_function(points, qc, qv, cur_estimate))) + std::max(0.0, dlib::length(pos) - 7.0);
        };

        auto stop_threshold = (options.stop_threshold == double()) ? 1e-7 : options.stop_threshold;
        auto deriv_eps = 1.4901161193847656e-08;

        if (options.stop_strategy == OBJECTIVE_DELTA) {
            auto stop_strategy = objective_delta_stop_strategy(stop_threshold, options.max_iter);

            if (options.verbose) stop_strategy.be_verbose();
            residual = find_min_using_approximate_derivatives(bfgs_search_strategy(),   // search strategy
                                                              stop_strategy,            // stop strategy
                                                              mean_err,                 // objective function to minimize
                                                              m,                        // initial / next solution
                                                              -1,                       // stop, if objective function is less or equal
                                                              deriv_eps);               // derivative epsilon
        } else {
            auto stop_strategy = gradient_norm_stop_strategy(stop_threshold, options.max_iter);

            if (options.verbose) stop_strategy.be_verbose();
            residual = find_min_using_approximate_derivatives(bfgs_search_strategy(),   // search strategy
                                                              stop_strategy,            // stop strategy
                                                              mean_err,                 // objective function to minimize
                                                              m,                        // initial / next solution
                                                              -1,                       // stop, if objective function is less or equal
                                                              deriv_eps);               // derivative epsilon
        }

        return residual;

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

/// FIXME: Shrink output for very long arrays
void print_array(std::string msg, const double a[], size_t len)
{
    printf("%s", msg.c_str());

    for (size_t i = 0; i < len; i++)
    {
        printf("%7.3f, ", a[i]);
    }

    printf("\n");
}

#ifdef __cplusplus
extern "C" {
#endif

double angle_between(const double v1[3], const double v2[3])
{
    relloc::vector3d _v1 = relloc::vector3d(v1[0], v1[1], v1[2]);
    relloc::vector3d _v2 = relloc::vector3d(v2[0], v2[1], v2[2]);

    relloc::vector3d v1_u = dlib::normalize(_v1);
    relloc::vector3d v2_u = dlib::normalize(_v2);

    return std::acos(std::clamp(dot(v1_u, v2_u), -1.0, 1.0));
}

void transform_points(size_t count, const double points[], const double tf[4], double* output) {
    point_transform_affine3d transform = relloc::make_transform(tf[0], tf[1], tf[2], tf[3]);

    std::vector<relloc::point3d> _p;
    std::vector<relloc::point3d> _output;

    _p.reserve(count);

    for (size_t i = 0; i < 3 * count; i += 3)
    {
        _p.push_back(relloc::point3d(points[i], points[i+1], points[i+2]));
    }

    _output = relloc::transform_points(_p, transform);

    memcpy(output, _output.data(), _output.size() * sizeof(double) * 3);
}

void error_function(size_t count, const double p[], const double qc[], const double qv[], const double x[4], double* err) {
    std::vector<relloc::point3d> _p;
    std::vector<relloc::point3d> _qc;
    std::vector<relloc::vector3d> _qv;
    std::vector<double> _err;

    relloc::column_vector _x = dlib::mat(x, 4);

    _p.reserve(count);
    _qc.reserve(count);
    _qv.reserve(count);

    for (size_t i = 0; i < 3 * count; i += 3)
    {
        _p.push_back(relloc::point3d(p[i], p[i+1], p[i+2]));
        _qc.push_back(relloc::point3d(qc[i], qc[i+1], qc[i+2]));
        _qv.push_back(relloc::vector3d(qv[i], qv[i+1], qv[i+2]));
    }

    _err = std::move(relloc::error_function(_p, _qc, _qv, _x));

    memcpy(err, _err.data(), _err.size() * sizeof(double) * 3);
}

double estimate_pose(size_t count, const double p[], const double qc[], const double qv[], double x[4], const options_t* options)
{
    std::vector<relloc::point3d> _p;
    std::vector<relloc::point3d> _qc;
    std::vector<relloc::vector3d> _qv;

    relloc::column_vector _x = dlib::mat(x, 4);

    _p.reserve(count);
    _qc.reserve(count);
    _qv.reserve(count);

    for (size_t i = 0; i < 3 * count; i += 3)
    {
        _p.push_back(relloc::point3d(p[i], p[i+1], p[i+2]));
        _qc.push_back(relloc::point3d(qc[i], qc[i+1], qc[i+2]));
        _qv.push_back(relloc::vector3d(qv[i], qv[i+1], qv[i+2]));
    }

    if (options->verbose)
    {
        print_array("p:\n", p, count * 3);
        print_array("qc:\n", qc, count * 3);
        print_array("qv:\n", qv, count * 3);
        print_array("x:\n", x, 4);
    }

    double res = relloc::estimate_pose(_p, _qc, _qv, _x, *options);

    memcpy(x, &(_x.steal_memory()[0]), sizeof(double) * 4);

    if (options->verbose)
    {
        print_array("new x:\n", x, 4);
    }

    return res;
}

#ifdef __cplusplus
}
#endif

