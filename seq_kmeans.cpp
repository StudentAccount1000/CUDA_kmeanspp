#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>
#include <cfloat>
#include <string>
#include <chrono>

#include "include/Centroid.h"
#include "include/Point.h"
#include "include/IOFile.h"

#define MAX_ITERATION 200
// #define DATA_LENGTH 2000
#define DATA_LENGTH 140000
// #define DATA_LENGTH 283894
#define PRECISION 5
#define K 7
#define SEQ_FILEPATH_PREFIX "SEQ"

int main(int argc, char**argv) {
    int k = K;

    Point * h_data = (Point *) malloc(sizeof(Point) * DATA_LENGTH);
    Centroid * h_centroids = (Centroid *) malloc(sizeof(Point) * K);
    // Point * h_data = new Point[2000];
    // Centroid * h_centroids = new Centroid[k];

    // read file data points to h_data
    read_file_to_arr(h_data);

    // construct filepath to read centroid data from – centroids selected using KMEANS++ algo
    const char* filepath = "";
    switch (k)
    {
    case 6:
        filepath = "./data/half_centroids/k6_centroids.txt";
        break;
    case 7:
        filepath = "./data/half_centroids/k7_centroids.txt";
        break;
    case 8:
        filepath = "./data/half_centroids/k8_centroids.txt";
        break;
    case 9:
        filepath = "./data/half_centroids/k9_centroids.txt";
        break;
    default:
        filepath = "./data/half_centroids/k7_centroids.txt";
        break;
    }

    // read centroids into centroids array
    read_file_to_arr(h_centroids, filepath);

    using std::chrono::high_resolution_clock;
    using std::chrono::duration_cast;
    using std::chrono::duration;
    using std::chrono::milliseconds;

    // begin clock
    auto t1 = high_resolution_clock::now();

    int counter = 0;
    const double epsilon = 1e-6;

    // main loop
    while (counter < MAX_ITERATION) {
        // assign points to clusters by calculating min distance from datapoint to centroids
        for (int i = 0; i < K; i++) {
            int clusterID = h_centroids[i].id;

            for (int j = 0; j < DATA_LENGTH; j++) {
                double distance = h_centroids[i].distance(h_data[j]);

                if (distance < h_data[j].minDist) {
                    h_data[j].minDist = distance;
                    h_data[j].clusterID = clusterID;
                }
            }

            h_centroids[i].nPoints = 0;
        }

        // iterate over points to calculate sum
        double sums[K][2];

        for (int i = 0; i < DATA_LENGTH; i++) {
            int clusterID = h_data[i].clusterID;
            h_centroids[clusterID].nPoints++;
            sums[clusterID][0] += h_data[i].x;
            sums[clusterID][1] += h_data[i].y;
        }

        bool converges = false;

        // compute new centroids
        for (int i = 0; i < K; i++) {
            // copy old centroid coordinates
            double old_centroid_x = h_centroids[i].x;
            double old_centroid_y = h_centroids[i].y;
            
            h_centroids[i].x = h_centroids[i].nPoints != 0 ? sums[i][0] / h_centroids[i].nPoints : old_centroid_x;
            h_centroids[i].y = h_centroids[i].nPoints != 0 ? sums[i][1] / h_centroids[i].nPoints : old_centroid_y;
            
            // reset sums and cluster data points count
            sums[i][0] = 0;
            sums[i][1] = 0;

            // compare new centroids with old_centroids
            // if not the same, set the flag to false
            if (std::abs(h_centroids[i].x - old_centroid_x) < epsilon &&
                std::abs(h_centroids[i].y - old_centroid_y) < epsilon) {
                converges = true;
            } else {
                // reset min distance
                h_data[i].minDist = DBL_MAX;
		converges = false;
            }
        }

        // if converge, break loop
        if (converges) {
            printf("converges at iteration: %d\n", counter+1);
            break;
        }

        counter++;
    }

    // end clock
    auto t2 = high_resolution_clock::now();

    // compute time took to execute algorithm
    auto ms_int = duration_cast<milliseconds>(t2 - t1);
    duration<double, std::milli> ms_double = t2 - t1;

    std::cout << ms_double.count() << "ms\n";

    const std::string filepath_prefix = SEQ_FILEPATH_PREFIX;

    write_array_to_csv(filepath_prefix, h_data, 7);
    write_centroids_to_txt(filepath_prefix, h_centroids, 7);

    return 0;
}
