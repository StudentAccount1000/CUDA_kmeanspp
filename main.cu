#define MAX_ITERATIONS 50
// #define DATA_LENGTH 2000
#define DATA_LENGTH 140000
// #define DATA_LENGTH 283894
#define MAX_THREADS_PER_BLOCK 1024
#define K 7                         // K # of clusters
#define CUDA_FILEPATH_PREFIX "CUDA"

#include <stdio.h>
#include <cuda.h>
#include <limits.h>
#include <stdlib.h>
#include <string>
#include <chrono>
#include <iostream>
#include <ctime>
#include <cstdlib>

#include "./include/Point.h"
#include "./include/Centroid.h"
#include "./include/IOFile.h"

#include <cfloat>

#if !defined(__CUDA_ARCH__) || __CUDA_ARCH__ >= 600
#else
__device__ double atomicAdd(double* address, double val)
{
    unsigned long long int* address_as_ull =
                              (unsigned long long int*)address;
    unsigned long long int old = *address_as_ull, assumed;

    do {
        assumed = old;
        old = atomicCAS(address_as_ull, assumed,
                        __double_as_longlong(val +
                               __longlong_as_double(assumed)));

    // Note: uses integer comparison to avoid hang in case of NaN (since NaN != NaN)
    } while (assumed != old);

    return __longlong_as_double(old);
}
#endif

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
   if (code != cudaSuccess) 
   {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}

#define CHECK_LAST_CUDA_ERROR() checkLast(__FILE__, __LINE__)
void checkLast(const char* const file, const int line)
{
    cudaError_t const err{cudaGetLastError()};
    if (err != cudaSuccess)
    {
        std::cerr << "CUDA Runtime Error at: " << file << ":" << line
                  << std::endl;
        std::cerr << cudaGetErrorString(err) << std::endl;
        // We don't exit when we encounter CUDA errors in this example.
        // std::exit(EXIT_FAILURE);
    }
}

// calculate minimum distance from datapoint to centroids
__global__ void calculate_min_distance(Point * datapoints, Centroid * centroids, int clusterID){
    int index = threadIdx.x + blockIdx.x * MAX_THREADS_PER_BLOCK;
    if (index < DATA_LENGTH) {
        // compute squares of x and  y
        double x_sqr = pow((datapoints[index].x - centroids[clusterID].x), 2.0);
        double y_sqr = pow((datapoints[index].y - centroids[clusterID].y), 2.0);

        // sum squares to get distance
        double distance = x_sqr + y_sqr;

        // update point cluster assignment if current distance is less than current minimum distance
        if (distance < datapoints[index].minDist) {
            datapoints[index].minDist = distance;
            datapoints[index].clusterID = clusterID;
        }
    }
}

// compute sums of datapoints within clusters
__global__ void compute_cluster_sums(Point * datapoints, Centroid * centroids, double * xsums, double * ysums) {
    int index = threadIdx.x + blockIdx.x * MAX_THREADS_PER_BLOCK;
    if (index < DATA_LENGTH) {
        // get current cluster ID
        int clusterID = datapoints[index].clusterID;

        // atomically add to avoid data race
        atomicAdd(&centroids[clusterID].nPoints, 1.0);
        atomicAdd(&xsums[clusterID], datapoints[index].x);
        atomicAdd(&ysums[clusterID], datapoints[index].y);

        // reset min distance
        datapoints[index].minDist = DBL_MAX;
    }
}

int main(int argc, char**argv) {
    int k = K;

    // check if user argument exists
    if (argc > 1) {
        k = atoi(argv[1]);
        if (k < 6 || k > 9) {
            printf("Please choose a K-value between 6-9\n");
            return 0;
        }
    }
    printf("K is: %d\n", k);
    
    // error checking
    if(k > DATA_LENGTH){
        printf("K must be less than the number of data points");
        return 1;
    }

    // allocate host memory
    Point * h_data = (Point*) malloc(sizeof(Point) * DATA_LENGTH); 
    Centroid * h_centroids = (Centroid*) malloc(sizeof(Centroid) * k);
    double * h_xsums = (double*) malloc(sizeof(double) * k);
    double * h_ysums = (double*) malloc(sizeof(double) * k);

    // allocate memory for GPU objects on host (later to be copied over to device)
    Point * d_data = (Point*) malloc(sizeof(Point) * DATA_LENGTH);
    Centroid * d_centroids = (Centroid*) malloc(sizeof(Centroid) * k);
    double * d_xsums = (double*) malloc(sizeof(double) * k);
    double * d_ysums = (double*) malloc(sizeof(double) * k);

    // read file data points to h_data
    read_file_to_arr(h_data);

    // use already computed centroid values as initial centroid values
    // see /test/init_centroids.py for details
    // const char* filepath = "";
    // switch (k)
    // {
    // case 6:
    //     filepath = "./data/half_centroids/k6_centroids.txt";
    //     break;
    // case 7:
    //     filepath = "./data/half_centroids/k7_centroids.txt";
    //     break;
    // case 8:
    //     filepath = "./data/half_centroids/k8_centroids.txt";
    //     break;
    // case 9:
    //     filepath = "./data/half_centroids/k9_centroids.txt";
    //     break;
    // default:
    //     filepath = "./data/half_centroids/k7_centroids.txt";
    //     break;
    // }

    // read centroids into centroids array
    // read_file_to_arr(h_centroids, filepath);

    // naive centroid selection – randomly select k centroids
    srand(time(NULL));
    for (int i = 0; i < k; ++i) {
        int randomIndex = rand() % DATA_LENGTH;
        std::cout << randomIndex << "\n";
        Centroid *c = new Centroid();
        c->x = latitude;
        c->y = longitude;
        c->id = curr_index;
        h_centroids[i] = *centroid;
    }

    // 512 threads and 4 blocks for current data
    int n_blocks = static_cast<int>(ceil(static_cast<double>(DATA_LENGTH)/static_cast<double>(MAX_THREADS_PER_BLOCK)));
    dim3 threads(MAX_THREADS_PER_BLOCK);
    dim3 blocks(n_blocks);

    // allocate memory on GPU and copy datapoints and centroids to GPU
    cudaMalloc((void**) &d_data, sizeof(Point) * DATA_LENGTH);
    cudaMalloc((void**) &d_centroids, sizeof(Centroid) * k);
    cudaMalloc((void**) &d_xsums, sizeof(double) * k);
    cudaMalloc((void**) &d_ysums, sizeof(double) * k);

    // check for cuda error
    CHECK_LAST_CUDA_ERROR();

    cudaMemcpy(d_data, h_data, sizeof(Point) * DATA_LENGTH, cudaMemcpyHostToDevice);
    cudaMemcpy(d_centroids, h_centroids, sizeof(Centroid) * k, cudaMemcpyHostToDevice);

    // check for cuda error
    CHECK_LAST_CUDA_ERROR();

    using std::chrono::high_resolution_clock;
    using std::chrono::duration_cast;
    using std::chrono::duration;
    using std::chrono::milliseconds;

    // start clock
    auto t1 = high_resolution_clock::now();

    int counter = 0;
    const double epsilon = 1e-6;

    // main loop
    while(counter < MAX_ITERATIONS) {
        // for each centroid, calculate the minimum distance to centroids
        for (int i = 0; i < k; i++) {
            calculate_min_distance<<<blocks, threads>>>(d_data, d_centroids, i);

            // make sure sums and centroids nPoints are reset
            // h_xsums[i] = 0;
            // h_ysums[i] = 0;
            // h_centroids[i].nPoints = 0;
        }

        // allocate memory on GPU for sums and copy resetted sums from host to device
        // cudaMalloc((void**) &d_xsums, sizeof(double) * k);
        // cudaMalloc((void**) &d_ysums, sizeof(double) * k);
        // cudaMemcpy(d_xsums, h_xsums, sizeof(double) * k, cudaMemcpyHostToDevice);
        // cudaMemcpy(d_ysums, h_ysums, sizeof(double) * k, cudaMemcpyHostToDevice);

        // for each cluster, compute the xsums and the ysums
        compute_cluster_sums<<<blocks, threads>>>(d_data, d_centroids, d_xsums, d_ysums);

        // copy centroids data and sums data from device to host
        cudaMemcpy(h_centroids, d_centroids, sizeof(Centroid) * k, cudaMemcpyDeviceToHost);
        cudaMemcpy(h_xsums, d_xsums, sizeof(double) * k, cudaMemcpyDeviceToHost);
        cudaMemcpy(h_ysums, d_ysums, sizeof(double) * k, cudaMemcpyDeviceToHost);

        // create a flag for convergence
        bool converges = false;

        // compute new centroids
        for (int i = 0; i < k; i++) {
            // copy old centroid coordinates
            double old_centroid_x = h_centroids[i].x;
            double old_centroid_y = h_centroids[i].y;

            // compute new centroids
            h_centroids[i].x = h_centroids[i].nPoints != 0 ? (h_xsums[i] / h_centroids[i].nPoints) : old_centroid_x;
            h_centroids[i].y = h_centroids[i].nPoints != 0 ? (h_ysums[i] / h_centroids[i].nPoints) : old_centroid_y;

            // reset sums and cluster data points count
            // h_xsums[i] = 0;
            // h_ysums[i] = 0;
            // h_centroids[i].nPoints = 0;

            // compare new centroids with old_centroids
            // if new centroids are same as old_centroids, set converge to true
            if (std::abs(h_centroids[i].x - old_centroid_x) < epsilon &&
                std::abs(h_centroids[i].y - old_centroid_y) < epsilon) {
                converges = true;
            } else {
		converges = false;
	    }
        }

        // if converge, break loop
        if (converges) {
            printf("converges at iteration: %d\n", counter+1);
            break;
        }

	// copy newly computed centroids and resetted sums from host to device
        cudaMemcpy(d_centroids, h_centroids, sizeof(Centroid) * k, cudaMemcpyHostToDevice);
        // cudaMemcpy(d_xsums, h_xsums, sizeof(double) * k, cudaMemcpyHostToDevice);
        // cudaMemcpy(d_ysums, h_ysums, sizeof(double) * k, cudaMemcpyHostToDevice);

        // deallocate and reset sums
        // cudaFree(d_xsums);
        // cudaFree(d_ysums);

        counter++;
    }

    // end clock
    auto t2 = high_resolution_clock::now();

    // // compute time took to execute algorithm
    duration<double, std::milli> ms_double = t2 - t1;

    std::cout << ms_double.count() << "ms\n";

    // copy datapoints with clusterID data from device to host
    cudaMemcpy(h_data, d_data, sizeof(Point) * DATA_LENGTH, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_centroids, d_centroids, sizeof(Centroid) * k, cudaMemcpyDeviceToHost);

    // // deallocate device memory
    cudaFree(d_data);
    cudaFree(d_centroids);
    cudaFree(d_xsums);
    cudaFree(d_ysums);
    printf("freed device  memory\n");

    // deallocate host memory
    // free(h_data);
    // free(h_centroids);
    // free(h_xsums);
    // free(h_ysums);
    // free(d_data);
    // free(d_centroids);
    // free(d_xsums);
    // free(d_ysums);
    // printf("freed host mem\n");

    const std::string filepath_prefix = CUDA_FILEPATH_PREFIX;

    write_array_to_csv(filepath_prefix, h_data, k);
    write_centroids_to_txt(filepath_prefix, h_centroids, k);

    printf("finished writing result to file\n");

    return 0;
}
