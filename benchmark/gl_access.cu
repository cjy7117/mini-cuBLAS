#include <iostream>
#include <stdio.h>
#include <climits>
#include <algorithm>
#include <cuda_profiler_api.h>
#define LL 30720 //15sm * 2048threads/sm
using namespace std;

__global__ void array_generator(double * A, int iteration, int access_per_iter) {
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  int L = gridDim.x * blockDim.x;
  for (int i = 0; i < iteration; i++) {
    double * nextA = A + L * access_per_iter;
    for (int j = 0; j < access_per_iter; j++) {
      *(A + L * j) = (unsigned long long int)( nextA + L * j );
    }
    A = nextA;
  }
}


__global__ void global_memory(double * A, int iteration, int access_per_iter,
                              unsigned long long int * dStart, unsigned long long int * dEnd) {
  extern __shared__ double cache[];
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;

  //volatile clock_t start = 0;
  //volatile clock_t end = 0;
  //volatile unsigned long long sum_time = 0;

  double * a_next1;
  double * a_next2;
 double * a_next3;
  double * a_next4;
  double * a_next5;
  double * a_next6;
  double * a_next7;
  double * a_next8;
  
  double * a_next9;
  double * a_next10;
  double * a_next11;
  double * a_next12;
  /*
  double * a_next13;
  double * a_next14;
  double * a_next15;
  double * a_next16;
  double * a_next17;
  double * a_next18;
  double * a_next19;
  double * a_next20;
  double * a_next21;
  double * a_next22;
  */
  double * a_curr1 = A;
  /*
  double * a_curr2 = A + LL;
  
  double * a_curr3 = A + LL * 2;
  double * a_curr4 = A + LL * 3;
  double * a_curr5 = A + LL * 4;
  double * a_curr6 = A + LL * 5;
  double * a_curr7 = A + LL * 6;
  double * a_curr8 = A + LL * 7;
  /*
  double * a_curr9 = A + LL * 8;
  double * a_curr10 = A + LL * 9;
  double * a_curr11 = A + LL * 10;
  double * a_curr12 = A + LL * 11;
  double * a_curr13 = A + LL * 12;
  double * a_curr14 = A + LL * 13;
  double * a_curr15 = A + LL * 14;
  double * a_curr16 = A + LL * 15;
  
  double * a_curr17 = A + LL * 16;
  double * a_curr18 = A + LL * 17;
  double * a_curr19 = A + LL * 18;
  double * a_curr20 = A + LL * 19;
  double * a_curr21 = A + LL * 20;
  double * a_curr22 = A + LL * 21;
  */
  for (int i = 0; i < iteration; i++) {
    //start = clock();                                                                                                                      
    a_next1 = (double *)(unsigned long long int) *a_curr1;
    a_next2 = (double *)(unsigned long long int) *(a_curr1 + LL);
    
    a_next3 = (double *)(unsigned long long int) *(a_curr1 + LL * 2);
    a_next4 = (double *)(unsigned long long int) *(a_curr1 + LL * 3);
    
    a_next5 = (double *)(unsigned long long int) *(a_curr1 + LL * 4);
    a_next6 = (double *)(unsigned long long int) *(a_curr1 + LL * 5);
    a_next7 = (double *)(unsigned long long int) *(a_curr1 + LL * 6);
    a_next8 = (double *)(unsigned long long int) *(a_curr1 + LL * 7);
    
    a_next9 = (double *)(unsigned long long int) *(a_curr1 + LL * 8);
    a_next10 = (double *)(unsigned long long int) *(a_curr1 + LL * 9);
    a_next11 = (double *)(unsigned long long int) *(a_curr1 + LL * 10);
    a_next12 = (double *)(unsigned long long int) *(a_curr1 + LL * 11);
    /*
    a_next13 = (double *)(unsigned long long int) *a_curr13;
    a_next14 = (double *)(unsigned long long int) *a_curr14;
    a_next15 = (double *)(unsigned long long int) *a_curr15;
    a_next16 = (double *)(unsigned long long int) *a_curr16;
    /*
    a_next17 = (double *)(unsigned long long int) *a_curr17;
    a_next18 = (double *)(unsigned long long int) *a_curr18;
    a_next19 = (double *)(unsigned long long int) *a_curr19;
    a_next20 = (double *)(unsigned long long int) *a_curr20;
    a_next21 = (double *)(unsigned long long int) *a_curr21;
    a_next22 = (double *)(unsigned long long int) *a_curr22;
    */
    __syncthreads();
    a_curr1 = a_next1;
    //a_curr1 += 12 * LL;

    /*a_curr2 = a_next2;
    
    a_curr3 = a_next3;
    a_curr4 = a_next4;
    
    a_curr5 = a_next5;
    a_curr6 = a_next6;
    a_curr7 = a_next7;
    a_curr8 = a_next8;
    /*
    a_curr9 = a_next9;
    a_curr10 = a_next10;
    a_curr11 = a_next11;
    a_curr12 = a_next12;
    a_curr13 = a_next13;
    a_curr14 = a_next14;
    a_curr15 = a_next15;
    /*
    a_curr16 = a_next16;
    a_curr17 = a_next17;
    a_curr18 = a_next18;
    a_curr19 = a_next19;
    a_curr20 = a_next20;
    a_curr21 = a_next21;
    a_curr22 = a_next22;
    */
    //end = clock(); 
  }
  
  *A += (unsigned long long int)a_next1;
  *A +=  (unsigned long long int)a_next2;
  *A +=  (unsigned long long int)a_next3;
  *A +=  (unsigned long long int)a_next4;
    
  *A +=  (unsigned long long int)a_next5;
  *A +=  (unsigned long long int)a_next6;
  *A +=  (unsigned long long int)a_next7;
  *A +=  (unsigned long long int)a_next8;// +
  
  *A +=  (unsigned long long int)a_next9;
  *A +=  (unsigned long long int)a_next10;
  *A +=  (unsigned long long int)a_next11;
  *A +=  (unsigned long long int)a_next12;
  /*
    (unsigned long long int)a_curr9 +
    (unsigned long long int)a_curr10 +
    (unsigned long long int)a_curr11 +
    (unsigned long long int)a_curr12 +
    (unsigned long long int)a_curr13 +
    (unsigned long long int)a_curr14 +
    (unsigned long long int)a_curr15 +
    (unsigned long long int)a_curr16;// +
    /*
    (unsigned long long int)a_curr17 +
    (unsigned long long int)a_curr18 +
    (unsigned long long int)a_curr19 +
    (unsigned long long int)a_curr20 + 
    (unsigned long long int)a_curr21 +
    (unsigned long long int)a_curr22;
    */
}



void test(int block_size){
  int iteration = 1000;
  int access_per_iter = 12;
  int SM = 15;
  int block_per_sm = 2048/block_size;
  int total_block = SM * block_per_sm;
  //int block_size = 1024;

  int n = total_block * block_size * access_per_iter * (iteration + 1);
  double * A = new double[n];
  unsigned long long int * start = new unsigned long long int[n];
  unsigned long long int * end = new unsigned long long int[n];
  unsigned long long int * dStart;
  unsigned long long int * dEnd;
  double * dA;
  cudaMalloc(&dA, (n) * sizeof(double));
  cudaMalloc((void**)&dStart, n * sizeof(unsigned long long int));
  cudaMalloc((void**)&dEnd, n * sizeof(unsigned long long int));

  array_generator<<<total_block, block_size>>>(dA, iteration, access_per_iter);
  cudaDeviceSynchronize();
  cudaError_t err = cudaGetLastError();
  if (err != cudaSuccess)
    printf("<array_gene>Error: %s\n", cudaGetErrorString(err));

  clock_t t = clock();
  global_memory<<<total_block, block_size, 49152 / block_per_sm>>>(dA, iteration, access_per_iter, dStart, dEnd);
  cudaDeviceSynchronize();
  t = clock() - t;

  float real_time = ((float)t)/CLOCKS_PER_SEC;
  cout <<"Runing time: " << real_time << " s." << endl;
  long long total_byte = total_block * block_size * sizeof(double) * access_per_iter;
  double total_gb = total_byte/1e9;
  total_gb *= iteration;
  cout << "Total data requested:"<<total_gb << " GB."<< endl;
  double throughput = total_gb/real_time;
  cout <<"Throughput: " << throughput << " GB/s." << endl;
  err = cudaGetLastError();
  if (err != cudaSuccess)
    printf("<global_memory>Error: %s\n", cudaGetErrorString(err));

  cudaMemcpy(A, dA, n * sizeof(double), cudaMemcpyDeviceToHost);

}

int main(){
  int i = 1024;
  //for (int i = 128; i < 2048; i *= 2) {
    cout << "block size: " << i << endl;
    test(i);
    //}

}