#include <stdlib.h>
#include <iostream>
#include "cublas_v2.h"
#include <cmath>
#include <time.h>
#include <stdio.h>
#include <string>
#include <stdlib.h>
#define TEST_RUN 1 
#define ESP 10e-10
#define PEAK_MEM 900
using namespace std;


void check_cuda_error(){
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess)
    printf("Error: %s\n", cudaGetErrorString(err));
}

void check_C(double * dC, int m, int n, double * checkC) {
  for (int i = 0; i < m * n; i++){
    //cout << i << endl;
    if (fabs(dC[i] - checkC[i]) > ESP){
      cout << "error:" << fabs(dC[i] - checkC[i]) << endl;
      return;
    }
  }
  //cout << "correct" << endl;
}

void output(int m, int n, int k, float min_time, float base, int blocksPerGrid_min, int threadsPerBlock_min, string func) {
  // long long total_bytes = (m * k + k * n * (k / 32)) * sizeof(double);
  long long total_bytes = (m * k + k * n * blocksPerGrid_min) * sizeof(double);
  double total_gb = (double)total_bytes / 1e9;
  total_gb *= TEST_RUN;
  // cout <<func << "("<< blocksPerGrid_min << "*" << threadsPerBlock_min << "): " << min_time << " s" 
  //      <<" ("  << base/min_time <<"x)."
  //      <<" (" << total_gb <<"GB)"
  //      <<" (" << total_gb/min_time <<"GB/s)"<<endl;
  cout << min_time << "," << base/min_time << "," << total_gb/min_time << "," << total_gb/min_time/PEAK_MEM << "\n";

}

/////////////////////////NAIVE/////////////////////////

__global__ void
dgemm_kernel_naive(int m, int n, int k, double * A, int lda, double * B, int ldb, double * C, int ldc)
{
  //determine the row to process                                                        
  register int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  register double a = 0;
  register double b = 0;
  register double temp = 0;
 
  for (int j = 0; j < n; j++) {
    #pragma unroll 1
    for (int i = 0; i < k; i+=1){
      //load data
      a = *(A + lda * i);
      b = *(B + ldb * j + i);
      //compute
      temp += a * b;
      
    }
    *(C + j * ldc + idx) = temp;
    temp = 0;
  }
  
}


__global__ void
dgemm_kernel_reduce_gld(int m, int n, int k, double * A, int lda, double * B, int ldb, double * C, int ldc)
{
  //determine the row to process                                                        
  register int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  register double temp1 = 0;
  register double temp2 = 0;
  register double temp3 = 0;
  register double temp4 = 0;
  register double temp5 = 0;
  register double temp6 = 0;
  register double temp7 = 0;
  register double temp8 = 0;
  register double temp9 = 0;
  register double temp10 = 0;
  register double temp11 = 0;
  register double temp12 = 0;
  register double temp13 = 0;
  register double temp14 = 0;
  register double temp15 = 0;
  register double temp16 = 0;

  register double a = 0;

  register double b1 = 0;
  register double b2 = 0;
  register double b3 = 0;
  register double b4 = 0;
  register double b5 = 0;
  register double b6 = 0;
  register double b7 = 0;
  register double b8 = 0;
  register double b9 = 0;
  register double b10 = 0;
  register double b11 = 0;
  register double b12 = 0;
  register double b13 = 0;
  register double b14 = 0;
  register double b15 = 0;
  register double b16 = 0;

  #pragma unroll 1
  for (int i = 0; i < k; i+=1){
    //load data
    a = *A;
    
    b1 = *B;
    b2 = *(B + ldb);
    b3 = *(B + ldb * 2);
    b4 = *(B + ldb * 3);
    b5 = *(B + ldb * 4);
    b6 = *(B + ldb * 5);
    b7 = *(B + ldb * 6);
    b8 = *(B + ldb * 7);
    b9 = *(B + ldb * 8);
    b10 = *(B + ldb * 9);
    b11 = *(B + ldb * 10);
    b12 = *(B + ldb * 11);
    b13 = *(B + ldb * 12);
    b14 = *(B + ldb * 13);
    b15 = *(B + ldb * 14);
    b16 = *(B + ldb * 15);


    A += lda;
    B += 1;

    //compute
    temp1 += a * b1;
    temp2 += a * b2;
    temp3 += a * b3;
    temp4 += a * b4;
    temp5 += a * b5;
    temp6 += a * b6;
    temp7 += a * b7;
    temp8 += a * b8;
    temp9 += a * b9;
    temp10 += a * b10;
    temp11 += a * b11;
    temp12 += a * b12;
    temp13 += a * b13;
    temp14 += a * b14;
    temp15 += a * b15;
    temp16 += a * b16;

  }

  *(C + 0 * ldc + idx) = temp1;
  *(C + 1 * ldc + idx) = temp2;
  *(C + 2 * ldc + idx) = temp3;
  *(C + 3 * ldc + idx) = temp4;
  *(C + 4 * ldc + idx) = temp5;
  *(C + 5 * ldc + idx) = temp6;
  *(C + 6 * ldc + idx) = temp7;
  *(C + 7 * ldc + idx) = temp8;
  *(C + 8 * ldc + idx) = temp9;
  *(C + 9 * ldc + idx) = temp10;
  *(C + 10 * ldc + idx) = temp11;
  *(C + 11 * ldc + idx) = temp12;
  *(C + 12 * ldc + idx) = temp13;
  *(C + 13 * ldc + idx) = temp14;
  *(C + 14 * ldc + idx) = temp15;
  *(C + 15 * ldc + idx) = temp16;
  
}


void test_kernel_naive(int m, int n, int k, 
            double * dA, int lda, 
            double * dB, int ldb, 
            double * dC, int ldc,
            float base){
  
  float min_time = 1000;
  int blocksPerGrid_min, threadsPerBlock_min;
  for (int T = 16; T <= min(1024, m); T *= 2) {
    // int T = 128;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;


    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < TEST_RUN; i++)
      dgemm_kernel_naive<<<blocksPerGrid, threadsPerBlock>>>(m, n, k,
                  dA, lda, dB, ldb, dC, ldc);
      check_cuda_error();
    cudaEventRecord(stop);

    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    float real_time = milliseconds / 1000;
    if (real_time < min_time) {
      min_time = real_time; 
      blocksPerGrid_min = blocksPerGrid;
      threadsPerBlock_min = threadsPerBlock;
    }
  }
  output(m, n, k, min_time, base, blocksPerGrid_min, threadsPerBlock_min, "V0");

}

void test_kernel_reduce_gld(int m, int n, int k, 
            double * dA, int lda, 
            double * dB, int ldb, 
            double * dC, int ldc,
            float base){
  
  float min_time = 1000;
  int blocksPerGrid_min, threadsPerBlock_min;
  for (int T = 16; T <= min(1024, m); T *= 2) {
    // int T = 128;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;


    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < TEST_RUN; i++)
      dgemm_kernel_reduce_gld<<<blocksPerGrid, threadsPerBlock>>>(m, n, k,
                  dA, lda, dB, ldb, dC, ldc);
      check_cuda_error();
    cudaEventRecord(stop);

    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    float real_time = milliseconds / 1000;
    if (real_time < min_time) {
      min_time = real_time; 
      blocksPerGrid_min = blocksPerGrid;
      threadsPerBlock_min = threadsPerBlock;
    }
  }
  output(m, n, k, min_time, base, blocksPerGrid_min, threadsPerBlock_min, "V1");
}


/////////////////////////SHARED/////////////////////////
__global__ void
dgemm_kernel_shared(int m, int n, int k, int T, double * A, int lda, double * B, int ldb, double * C, int ldc)
{
  // store B (T * 2)
  extern __shared__ double cache[];
  
  //determine the row to process
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  register double temp1 = 0;
  register double temp2 = 0;
  register double temp3 = 0;
  register double temp4 = 0;
  register double temp5 = 0;
  register double temp6 = 0;
  register double temp7 = 0;
  register double temp8 = 0;
  register double temp9 = 0;
  register double temp10 = 0;
  register double temp11 = 0;
  register double temp12 = 0;
  register double temp13 = 0;
  register double temp14 = 0;
  register double temp15 = 0;
  register double temp16 = 0;

  register double a = 0;

  for (int j = 0; j < k; j += T){
    cache[threadIdx.x * 16 + 0] = *(B + threadIdx.x + ldb * 0);
    cache[threadIdx.x * 16 + 1] = *(B + threadIdx.x + ldb * 1);
    cache[threadIdx.x * 16 + 2] = *(B + threadIdx.x + ldb * 2);
    cache[threadIdx.x * 16 + 3] = *(B + threadIdx.x + ldb * 3);
    
    cache[threadIdx.x * 16 + 4] = *(B + threadIdx.x + ldb * 4);
    cache[threadIdx.x * 16 + 5] = *(B + threadIdx.x + ldb * 5);
    cache[threadIdx.x * 16 + 6] = *(B + threadIdx.x + ldb * 6);
    cache[threadIdx.x * 16 + 7] = *(B + threadIdx.x + ldb * 7);
  
    cache[threadIdx.x * 16 + 8] = *(B + threadIdx.x + ldb * 8);
    cache[threadIdx.x * 16 + 9] = *(B + threadIdx.x + ldb * 9);
    cache[threadIdx.x * 16 + 10] = *(B + threadIdx.x + ldb * 10);
    cache[threadIdx.x * 16 + 11] = *(B + threadIdx.x + ldb * 11);
    
    cache[threadIdx.x * 16 + 12] = *(B + threadIdx.x + ldb * 12);
    cache[threadIdx.x * 16 + 13] = *(B + threadIdx.x + ldb * 13);
    cache[threadIdx.x * 16 + 14] = *(B + threadIdx.x + ldb * 14);
    cache[threadIdx.x * 16 + 15] = *(B + threadIdx.x + ldb * 15);
    __syncthreads();
    B += T;
    for (int i = 0; i < T; i++) {
      a = *(A + (i + j) * lda);

      temp1 += a * cache[i * 16 + 0];
      temp2 += a * cache[i * 16 + 1];
      temp3 += a * cache[i * 16 + 2];
      temp4 += a * cache[i * 16 + 3];

      temp5 += a * cache[i * 16 + 4];
      temp6 += a * cache[i * 16 + 5];
      temp7 += a * cache[i * 16 + 6];
      temp8 += a * cache[i * 16 + 7];

      temp9 += a * cache[i * 16 + 8];
      temp10 += a * cache[i * 16 + 9];
      temp11 += a * cache[i * 16 + 10];
      temp12 += a * cache[i * 16 + 11];

      temp13 += a * cache[i * 16 + 12];
      temp14 += a * cache[i * 16 + 13];
      temp15 += a * cache[i * 16 + 14];
      temp16 += a * cache[i * 16 + 15];

    }
    __syncthreads();

  }
  *(C + 0 * ldc + idx) = temp1;
  *(C + 1 * ldc + idx) = temp2;
  *(C + 2 * ldc + idx) = temp3;
  *(C + 3 * ldc + idx) = temp4;

  *(C + 4 * ldc + idx) = temp5;
  *(C + 5 * ldc + idx) = temp6;
  *(C + 6 * ldc + idx) = temp7;
  *(C + 7 * ldc + idx) = temp8;

  *(C + 8 * ldc + idx) = temp9;
  *(C + 9 * ldc + idx) = temp10;
  *(C + 10 * ldc + idx) = temp11;
  *(C + 11 * ldc + idx) = temp12;

  *(C + 12 * ldc + idx) = temp13;
  *(C + 13 * ldc + idx) = temp14;
  *(C + 14 * ldc + idx) = temp15;
  *(C + 15 * ldc + idx) = temp16;

}


float test_kernel_shared(int m, int n, int k, 
          double * dA, int lda, 
          double * dB, int ldb, 
          double * dC, int ldc,
          float base){
  float min_time = 1000;
  int blocksPerGrid_min, threadsPerBlock_min;
  for (int T = 16; T <= min(256, m); T *= 2) { // T <= 256 limited by shared memory per thread block

    //int T = 16;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;
    
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < TEST_RUN; i++)
      dgemm_kernel_shared<<<blocksPerGrid, threadsPerBlock,  T * sizeof(double) * 16>>>(m, n, k, T, dA, lda, dB, ldb, dC, ldc);
      check_cuda_error();
    cudaEventRecord(stop);

    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    float real_time = milliseconds / 1000;
    if (real_time < min_time) {
      min_time = real_time; 
      blocksPerGrid_min = blocksPerGrid;
      threadsPerBlock_min = threadsPerBlock;
    }
  }
  output(m, n, k, min_time, base, blocksPerGrid_min, threadsPerBlock_min, "V2");
}

///////////////////////A PREFETCH(cache<->register)
__global__ void
dgemm_kernel_prefetch_s2r_16(int m, int n, int k, int T, double * A, int lda, double * B, int ldb, double * C, int ldc)
{

  extern __shared__ double cache[];
  
  double * cacheA = cache;
  double * cacheB = cache + T * T;
  
  //determine the row to process
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  double temp1 = 0;
  double temp2 = 0;
  double temp3 = 0;
  double temp4 = 0;

//prefectch A
  for (int i = 0; i < T; i++){
    cacheA[threadIdx.x + i * T] = *(A + i * lda);
  }
  
  double r0, r1, r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15;

  for (int j = 0; j < k; j += T){
    
    __syncthreads();
    cacheB[threadIdx.x * 4] = *(B + threadIdx.x);
    cacheB[threadIdx.x * 4 + 1] = *(B + threadIdx.x + ldb);
    cacheB[threadIdx.x * 4 + 2] = *(B + threadIdx.x + ldb * 2);
    cacheB[threadIdx.x * 4 + 3] = *(B + threadIdx.x + ldb * 3);
    __syncthreads();
    B += T;

    if (j + T < k) {  
      A = A + T * lda;
      
      r0 = *(A + 0 *lda);
      r1 = *(A + 1 *lda);
      r2 = *(A + 2 *lda);
      r3 = *(A + 3 *lda);   
      r4 = *(A + 4 *lda);
      r5 = *(A+ 5 *lda);
      r6 = *(A + 6 *lda);
      r7 = *(A + 7 *lda);

      r8 = *(A + 8 *lda);
      r9 = *(A + 9 *lda);
      r10 = *(A + 10 *lda);
      r11 = *(A + 11 *lda);
      r12 = *(A + 12 *lda);
      r13 = *(A + 13 *lda);
      r14 = *(A + 14 *lda);
      r15 = *(A + 15 *lda);
    }

    for (int i = 0; i < T; i++) {      
      temp1 += cacheA[threadIdx.x +i * T] * cacheB[i * 4];
      temp2 += cacheA[threadIdx.x +i * T] * cacheB[i * 4 + 1];
      temp3 += cacheA[threadIdx.x +i * T] * cacheB[i * 4 + 2];
      temp4 += cacheA[threadIdx.x +i * T] * cacheB[i * 4 + 3];
    }
    if (j + T < k) {
      cacheA[threadIdx.x + 0 * T] = r0;
      cacheA[threadIdx.x + 1 * T] = r1;
      cacheA[threadIdx.x + 2 * T] = r2;
      cacheA[threadIdx.x + 3 * T] = r3;
      cacheA[threadIdx.x + 4 * T] = r4;
      cacheA[threadIdx.x + 5 * T] = r5;
      cacheA[threadIdx.x + 6 * T] = r6;
      cacheA[threadIdx.x + 7 * T] = r7;

      cacheA[threadIdx.x + 8 * T] = r8;
      cacheA[threadIdx.x + 9 * T] = r9;
      cacheA[threadIdx.x + 10 * T] = r10;
      cacheA[threadIdx.x + 11 * T] = r11;
      cacheA[threadIdx.x + 12 * T] = r12;
      cacheA[threadIdx.x + 13 * T] = r13;
      cacheA[threadIdx.x + 14 * T] = r14;
      cacheA[threadIdx.x + 15 * T] = r15;
    }

  }
  *(C + 0 * ldc + idx) = temp1;
  *(C + 1 * ldc + idx) = temp2;
  *(C + 2 * ldc + idx) = temp3;
  *(C + 3 * ldc + idx) = temp4;

}


__global__ void
dgemm_kernel_prefetch_s2r_8(int m, int n, int k, int T, double * A, int lda, double * B, int ldb, double * C, int ldc)
{

  extern __shared__ double cache[];
  
  double * cacheA = cache;
  double * cacheB = cache + T * T;
  
  //determine the row to process
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  double temp1 = 0;
  double temp2 = 0;
  double temp3 = 0;
  double temp4 = 0;

//prefectch A
  for (int i = 0; i < T; i++){
    cacheA[threadIdx.x + i * T] = *(A + i * lda);
  }
  
  double r0, r1, r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15;

  for (int j = 0; j < k; j += T){
    
    __syncthreads();
    cacheB[threadIdx.x * 4] = *(B + threadIdx.x);
    cacheB[threadIdx.x * 4 + 1] = *(B + threadIdx.x + ldb);
    cacheB[threadIdx.x * 4 + 2] = *(B + threadIdx.x + ldb * 2);
    cacheB[threadIdx.x * 4 + 3] = *(B + threadIdx.x + ldb * 3);
    __syncthreads();
    B += T;

    if (j + T < k) {  
      A = A + T * lda;
      
      r0 = *(A + 0 *lda);
      r1 = *(A + 1 *lda);
      r2 = *(A + 2 *lda);
      r3 = *(A + 3 *lda);   
      r4 = *(A + 4 *lda);
      r5 = *(A+ 5 *lda);
      r6 = *(A + 6 *lda);
      r7 = *(A + 7 *lda);
    }

    for (int i = 0; i < T; i++) {      
      temp1 += cacheA[threadIdx.x +i * T] * cacheB[i * 4];
      temp2 += cacheA[threadIdx.x +i * T] * cacheB[i * 4 + 1];
      temp3 += cacheA[threadIdx.x +i * T] * cacheB[i * 4 + 2];
      temp4 += cacheA[threadIdx.x +i * T] * cacheB[i * 4 + 3];
    }
    if (j + T < k) {
      cacheA[threadIdx.x + 0 * T] = r0;
      cacheA[threadIdx.x + 1 * T] = r1;
      cacheA[threadIdx.x + 2 * T] = r2;
      cacheA[threadIdx.x + 3 * T] = r3;
      cacheA[threadIdx.x + 4 * T] = r4;
      cacheA[threadIdx.x + 5 * T] = r5;
      cacheA[threadIdx.x + 6 * T] = r6;
      cacheA[threadIdx.x + 7 * T] = r7;
    }

  }
  *(C + 0 * ldc + idx) = temp1;
  *(C + 1 * ldc + idx) = temp2;
  *(C + 2 * ldc + idx) = temp3;
  *(C + 3 * ldc + idx) = temp4;

}


void test_kernel_prefetch(int m, int n, int k, 
            double * dA, int lda, 
            double * dB, int ldb, 
            double * dC, int ldc,
            float base){

  float min_time = 1000;
  int blocksPerGrid_min, threadsPerBlock_min;
  for (int T = 8; T <= 16; T *= 2) {
    //int T = 16;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < TEST_RUN; i++) {
      if (T == 16)
        dgemm_kernel_prefetch_s2r_16<<<blocksPerGrid, threadsPerBlock, ((T * 4) + (T * T)) * sizeof(double)>>>(m, n, k, T, dA, lda, dB, ldb, dC, ldc);
      else if (T == 8)
        dgemm_kernel_prefetch_s2r_8<<<blocksPerGrid, threadsPerBlock, ((T * 4) + (T * T)) * sizeof(double)>>>(m, n, k, T, dA, lda, dB, ldb, dC, ldc);
      check_cuda_error();
    }
    cudaEventRecord(stop);

    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    float real_time = milliseconds / 1000;
    if (real_time < min_time) {
      min_time = real_time; 
      blocksPerGrid_min = blocksPerGrid;
      threadsPerBlock_min = threadsPerBlock;
    }
  }
  output(m, n, k, min_time, base, blocksPerGrid_min, threadsPerBlock_min, "V3-1");
}



//Single registers: m, n, k, T, t, lda, ldb, ldc, idx, i, j, l (12)
//Double registers: cache, cacheA, cacheB, A, B, C, r0-3, temp1-2 (22)
//Shared mem.: T*2 + T*T (double)
__global__ void
dgemm_kernel_prefetch_s2r_4_16(int m, int n, int k, int T, int t, double * A, int lda, double * B, int ldb, double * C, int ldc)
{
  // store B (T * 2)                                                                                                                                                                                                                                                                       
  extern __shared__ double cache[];
 
  double * cacheA = cache;
  double * cacheB = cache + T * t; //32 threads * 8 elements

  //determine the row to process                                                                                                                                                                                                                                                           
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  double temp1 = 0;
  double temp2 = 0;
  double temp3 = 0;
  double temp4 = 0;

  #pragma unroll 1
  //prefectch A 
  for (int i = 0; i < t; i++){
    cacheA[threadIdx.x + i * T] = *(A + i * lda);
  }
  A += t * lda;

  double r0, r1, r2, r3;

  #pragma unroll 1
  for (int j = 0; j < k; j += T){ 
    __syncthreads();
    cacheB[threadIdx.x * 4] = *(B + threadIdx.x);
    cacheB[threadIdx.x * 4 + 1] = *(B + threadIdx.x + ldb);
    cacheB[threadIdx.x * 4 + 2] = *(B + threadIdx.x + ldb * 2);
    cacheB[threadIdx.x * 4 + 3] = *(B + threadIdx.x + ldb * 3);
    __syncthreads();
    B += T;

    #pragma unroll 1
    for (int l = j; l < j + T; l += t){
      if (l + t < k) {
        r0 = *(A + 0 *lda);
        r1 = *(A + 1 *lda);
        r2 = *(A + 2 *lda);
        r3 = *(A + 3 *lda); 
      }

      #pragma unroll 1
      for (int i = 0; i < t; i++) {
        temp1 += cacheA[threadIdx.x +i * T] * cacheB[l - j + i ];
        temp2 += cacheA[threadIdx.x +i * T] * cacheB[l - j + i + 1];
        temp3 += cacheA[threadIdx.x +i * T] * cacheB[l - j + i + 2];
        temp4 += cacheA[threadIdx.x +i * T] * cacheB[l - j + i + 3];
      }
      if (l + t < k) {
      cacheA[threadIdx.x + 0 * T] = r0;
      cacheA[threadIdx.x + 1 * T] = r1;
      cacheA[threadIdx.x + 2 * T] = r2;
      cacheA[threadIdx.x + 3 * T] = r3;
      }
      A += t * lda;
    }
  }
  *(C + 0 * ldc + idx) = temp1;
  *(C + 1 * ldc + idx) = temp2;
  *(C + 2 * ldc + idx) = temp3;
  *(C + 3 * ldc + idx) = temp4;
    
}

void test_kernel_prefetch2(int m, int n, int k, 
            double * dA, int lda, 
            double * dB, int ldb, 
            double * dC, int ldc,
            float base){    
    int T = 64;
    int tt = 4;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < TEST_RUN; i++){
      dgemm_kernel_prefetch_s2r_4_16<<<blocksPerGrid, threadsPerBlock, ((T * 4) + (T * tt)) * sizeof(double)>>>(m, n, k, T, tt, dA, lda, dB, ldb, dC, ldc);
      check_cuda_error();
    }
    cudaEventRecord(stop);

    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    float real_time = milliseconds / 1000;
    output(m, n, k, real_time, base, blocksPerGrid, threadsPerBlock, "V3-2");

}



//Single registers: m, n, k, T, t, lda, ldb, ldc, idx, j, l (11)
//Double registers: cacheB, A, B, C, nr0-3, cr0-3, temp1-2 (28)
//Shared mem.: T*2 + T*T (double)
//#define t 4
__global__ void
dgemm_kernel4_2(int m, int n, int k, int T, int t, double * A, int lda, double * B, int ldb, double * C, int ldc)
{
  // store B (T * 2)                                                                                                                                                                                                                                                                       
  extern __shared__ double cacheB[];

  //determine the row to process                                                                                                                                                                                                                          
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  C = C + idx;
  register double temp1 = 0;
  register double temp2 = 0;
  register double temp3 = 0;
  register double temp4 = 0;
  register double temp5 = 0;
  register double temp6 = 0;
  register double temp7 = 0;
  register double temp8 = 0;
  register double temp9 = 0;
  register double temp10 = 0;
  register double temp11 = 0;
  register double temp12 = 0;
  register double temp13 = 0;
  register double temp14 = 0;
  register double temp15 = 0;
  register double temp16 = 0;


  register double nr0, nr1, nr2, nr3;
  register double cr0, cr1, cr2, cr3;

  //prefectch A 
  cr0 = *A;
  A += lda;
  cr1 = *A;
  A += lda;
  
  cr2 = *A;
  A += lda;
  cr3 = *A;
  A += lda;

  #pragma unroll 1
  for (int j = 0; j < k; j += T){ 

    __syncthreads();
    cacheB[threadIdx.x * 16] = *(B + threadIdx.x);
    cacheB[threadIdx.x * 16 + 1] = *(B + threadIdx.x + ldb);
    cacheB[threadIdx.x * 16 + 2] = *(B + threadIdx.x + ldb * 2);
    cacheB[threadIdx.x * 16 + 3] = *(B + threadIdx.x + ldb * 3);
    cacheB[threadIdx.x * 16 + 4] = *(B + threadIdx.x + ldb * 4);
    cacheB[threadIdx.x * 16 + 5] = *(B + threadIdx.x + ldb * 5);
    cacheB[threadIdx.x * 16 + 6] = *(B + threadIdx.x + ldb * 6);
    cacheB[threadIdx.x * 16 + 7] = *(B + threadIdx.x + ldb * 7);
    cacheB[threadIdx.x * 16 + 8] = *(B + threadIdx.x + ldb * 8);
    cacheB[threadIdx.x * 16 + 9] = *(B + threadIdx.x + ldb * 9);
    cacheB[threadIdx.x * 16 + 10] = *(B + threadIdx.x + ldb * 10);
    cacheB[threadIdx.x * 16 + 11] = *(B + threadIdx.x + ldb * 11);
    cacheB[threadIdx.x * 16 + 12] = *(B + threadIdx.x + ldb * 12);
    cacheB[threadIdx.x * 16 + 13] = *(B + threadIdx.x + ldb * 13);
    cacheB[threadIdx.x * 16 + 14] = *(B + threadIdx.x + ldb * 14);
    cacheB[threadIdx.x * 16 + 15] = *(B + threadIdx.x + ldb * 15);
    __syncthreads();
    B += T;

    #pragma unroll 1
    for (int l = j; l < j + T; l += t){
      if (l + t < k) {
        nr0 = *A;
        A += lda;
        nr1 = *A;
        A += lda;

        nr2 = *A;
        A += lda;
        nr3 = *A;
        A += lda;
      }

      temp1 += cr0 * cacheB[l - j + 0 ];
      temp2 += cr0 * cacheB[l - j + 0 + 1];
      temp3 += cr0 * cacheB[l - j + 0 + 2];
      temp4 += cr0 * cacheB[l - j + 0 + 3];
      temp5 += cr0 * cacheB[l - j + 0 + 4];
      temp6 += cr0 * cacheB[l - j + 0 + 5];
      temp7 += cr0 * cacheB[l - j + 0 + 6];
      temp8 += cr0 * cacheB[l - j + 0 + 7];
      temp9 += cr0 * cacheB[l - j + 0  + 8];
      temp10 += cr0 * cacheB[l - j + 0 + 9];
      temp11 += cr0 * cacheB[l - j + 0 + 10];
      temp12 += cr0 * cacheB[l - j + 0 + 11];
      temp13 += cr0 * cacheB[l - j + 0 + 12];
      temp14 += cr0 * cacheB[l - j + 0 + 13];
      temp15 += cr0 * cacheB[l - j + 0 + 14];
      temp16 += cr0 * cacheB[l - j + 0 + 15];

      temp1 += cr1 * cacheB[l - j + 1 ];
      temp2 += cr1 * cacheB[l - j + 1 + 1];
      temp3 += cr1 * cacheB[l - j + 1 + 2];
      temp4 += cr1 * cacheB[l - j + 1 + 3];
      temp5 += cr1 * cacheB[l - j + 1 + 4];
      temp6 += cr1 * cacheB[l - j + 1 + 5];
      temp7 += cr1 * cacheB[l - j + 1 + 6];
      temp8 += cr1 * cacheB[l - j + 1 + 7];
      temp9 += cr1 * cacheB[l - j + 1  + 8];
      temp10 += cr1 * cacheB[l - j + 1 + 9];
      temp11 += cr1 * cacheB[l - j + 1 + 10];
      temp12 += cr1 * cacheB[l - j + 1 + 11];
      temp13 += cr1 * cacheB[l - j + 1 + 12];
      temp14 += cr1 * cacheB[l - j + 1 + 13];
      temp15 += cr1 * cacheB[l - j + 1 + 14];
      temp16 += cr1 * cacheB[l - j + 1 + 15];

      temp1 += cr2 * cacheB[l - j + 2 ];
      temp2 += cr2 * cacheB[l - j + 2 + 1];
      temp3 += cr2 * cacheB[l - j + 2 + 2];
      temp4 += cr2 * cacheB[l - j + 2 + 3];
      temp5 += cr2 * cacheB[l - j + 2 + 4];
      temp6 += cr2 * cacheB[l - j + 2 + 5];
      temp7 += cr2 * cacheB[l - j + 2 + 6];
      temp8 += cr2 * cacheB[l - j + 2 + 7];
      temp9 += cr2 * cacheB[l - j + 2 + 8];
      temp10 += cr2 * cacheB[l - j + 2 + 9];
      temp11 += cr2 * cacheB[l - j + 2 + 10];
      temp12 += cr2 * cacheB[l - j + 2 + 11];
      temp13 += cr2 * cacheB[l - j + 2 + 12];
      temp14 += cr2 * cacheB[l - j + 2 + 13];
      temp15 += cr2 * cacheB[l - j + 2 + 14];
      temp16 += cr2 * cacheB[l - j + 2 + 15];

      temp1 += cr3 * cacheB[l - j + 3 ];
      temp2 += cr3 * cacheB[l - j + 3 + 1];
      temp3 += cr3 * cacheB[l - j + 3 + 2];
      temp4 += cr3 * cacheB[l - j + 3 + 3];
      temp5 += cr3 * cacheB[l - j + 3 + 4];
      temp6 += cr3 * cacheB[l - j + 3 + 5];
      temp7 += cr3 * cacheB[l - j + 3 + 6];
      temp8 += cr3 * cacheB[l - j + 3 + 7];
      temp9 += cr3 * cacheB[l - j + 3 + 8 ];
      temp10 += cr3 * cacheB[l - j + 3 + 9];
      temp11 += cr3 * cacheB[l - j + 3 + 10];
      temp12 += cr3 * cacheB[l - j + 3 + 11];
      temp13 += cr3 * cacheB[l - j + 3 + 12];
      temp14 += cr3 * cacheB[l - j + 3 + 13];
      temp15 += cr3 * cacheB[l - j + 3 + 14];
      temp16 += cr3 * cacheB[l - j + 3 + 15];

      if (l + t < k) {
        cr0 = nr0;
        cr1 = nr1;
        cr2 = nr2;
        cr3 = nr3;
      }
    }
  }
  *C = temp1;
  *(C + ldc) = temp2;
  *(C + ldc * 2) = temp3;
  *(C + ldc * 3) = temp4;
  *(C + ldc * 4) = temp5;
  *(C + ldc * 5) = temp6;
  *(C + ldc * 6) = temp7;
  *(C + ldc * 7) = temp8;
  *(C + ldc * 8) = temp9;
  *(C + ldc * 9) = temp10;
  *(C + ldc * 10) = temp11;
  *(C + ldc * 11) = temp12;
  *(C + ldc * 12) = temp13;
  *(C + ldc * 13) = temp14;
  *(C + ldc * 14) = temp15;
  *(C + ldc * 15) = temp16;

    
}





//Single registers: m, n, k, T, t, lda, ldb, ldc, idx, j, l (11)
//Double registers: cacheB, A, B, C, nr0-3, cr0-3, temp1-2 (28)
//Shared mem.: T*2 + T*T (double)

__global__ void
dgemm_kernel4_3(int m, int n, int k, int T, int t, double * A, int lda, double * B, int ldb, double * C, int ldc)
{
                                                                                                                                                                                                                
  // //determine the row to process                                                                                                                                                                                                                          
  // int idx = blockIdx.x * blockDim.x + threadIdx.x;
  // A = A + idx;
  // C = C + idx;
  // register double temp1 = 0;
  // register double temp2 = 0;
  // register double temp3 = 0;
  // register double temp4 = 0;

  // register double nr0, nr1;//, nr2, nr3;
  // register double cr0, cr1;//, cr2, cr3;

  // register double nb00, nb01, nb02, nb03;//, nb10, nb11, nb12, nb13;
  // register double cb00, cb01, cb02, cb03;//, cb10, cb11, cb12, cb13;

  // //prefectch A 
  // cr0 = *A;
  // A += lda;
  // cr1 = *A;
  // A += lda;
  
  // // cr2 = *A;
  // // A += lda;
  // // cr3 = *A;
  // // A += lda;

  // cb00 = *B;
  // cb01 = *(B + ldb);
  // cb02 = *(B + ldb * 2);
  // cb03 = *(B + ldb * 3);
  // B += 1;
  // // cb10 = *B;
  // // cb11 = *(B + ldb);
  // // cb12 = *(B + ldb * 2);
  // // cb13 = *(B + ldb * 3);
  // // B += 1;


  // #pragma unroll 1
  // for (int i = 0; i < k; i += t){ 
  //     if (i + t < k) {
  //       nr0 = *A;
  //       A += lda;
  //       nr1 = *A;
  //       A += lda;

  //       // nr2 = *A;
  //       // A += lda;
  //       // nr3 = *A;
  //       // A += lda;
  //     }

  //     nb00 = *B;
  //     nb01 = *(B + ldb);
  //     // nb02 = *(B + ldb * 2);
  //     // nb03 = *(B + ldb * 3);
  //     B += 1;
  //     // nb10 = *B;
  //     // nb11 = *(B + ldb);
  //     // nb12 = *(B + ldb * 2);
  //     // nb13 = *(B + ldb * 3);
  //     // B += 1;

  //     temp1 += cr0 * cb00;
  //     temp2 += cr0 * cb01;
  //     temp3 += cr0 * cb02;
  //     temp4 += cr0 * cb03;

  //     // temp1 += cr1 * cb10;
  //     // temp2 += cr1 * cb11;
  //     // temp3 += cr1 * cb12;
  //     // temp4 += cr1 * cb13;

  //     cb00 = nb00;
  //     cb01 = nb01;
  //     cb02 = nb02;
  //     cb03 = nb03;

  //     // cb10 = nb10;
  //     // cb11 = nb11;
  //     // cb12 = nb12;
  //     // cb13 = nb13;

  //     nb00 = *B;
  //     nb01 = *(B + ldb);
  //     nb02 = *(B + ldb * 2);
  //     nb03 = *(B + ldb * 3);
  //     B += 1;

  //     temp1 += cr1 * cb00;
  //     temp2 += cr1 * cb01;
  //     temp3 += cr1 * cb02;
  //     temp4 += cr1 * cb03;

  //     cb00 = nb00;
  //     cb01 = nb01;
  //     cb02 = nb02;
  //     cb03 = nb03;



  //     // nb00 = *B;
  //     // nb01 = *(B + ldb);
  //     // nb02 = *(B + ldb * 2);
  //     // nb03 = *(B + ldb * 3);
  //     // B += 1;

  //     // temp1 += cr2 * cb00;
  //     // temp2 += cr2 * cb01;
  //     // temp3 += cr2 * cb02;
  //     // temp4 += cr2 * cb03;

  //     // cb00 = nb00;
  //     // cb01 = nb01;
  //     // cb02 = nb02;
  //     // cb03 = nb03;




  //     // if (i + t < k) {
  //     //   nb00 = *B;
  //     //   nb01 = *(B + ldb);
  //     //   nb02 = *(B + ldb * 2);
  //     //   nb03 = *(B + ldb * 3);
  //     //    B += 1;
  //     //   // nb10 = *B;
  //     //   // nb11 = *(B + ldb);
  //     //   // nb12 = *(B + ldb * 2);
  //     //   // nb13 = *(B + ldb * 3);
  //     //   // B += 1;
  //     // }

  //     // temp1 += cr3 * cb00;
  //     // temp2 += cr3 * cb01;
  //     // temp3 += cr3 * cb02;
  //     // temp4 += cr3 * cb03;
  //     // // temp1 += cr4 * cb10;
  //     // // temp2 += cr4 * cb11;

  //     // cb00 = nb00;
  //     // cb01 = nb01;
  //     // cb02 = nb02;
  //     // cb03 = nb03;

  //     // // cb10 = nb10;
  //     // // cb11 = nb11;
  //     // // cb12 = nb12;
  //     // // cb13 = nb13;
    

  //     if (i + t < k) {
  //       cr0 = nr0;
  //       cr1 = nr1;
  //       // cr2 = nr2;
  //       // cr3 = nr3;
  //     }
  // }
  // *C = temp1;
  // *(C + ldc) = temp2;
  // *(C + ldc * 2) = temp3;
  // *(C + ldc * 3) = temp4;
    
}


float test_kernel_prefetch3(int m, int n, int k, 
            double * dA, int lda, 
            double * dB, int ldb, 
            double * dC, int ldc,
            float base){

  float min_time = 1000;
  int blocksPerGrid_min, threadsPerBlock_min;
  for (int T = 16; T <= min(m, 256); T*=2) {
    //int T = 128;
    int tt = 4;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < TEST_RUN; i++) {
      dgemm_kernel4_2<<<blocksPerGrid, threadsPerBlock, (T * 16) * sizeof(double)>>>(m, n, k, T, tt, dA, lda, dB, ldb, dC, ldc);
      check_cuda_error();
    }
    cudaEventRecord(stop);

    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    float real_time = milliseconds / 1000;
    if (real_time < min_time) {
      min_time = real_time; 
      blocksPerGrid_min = blocksPerGrid;
      threadsPerBlock_min = threadsPerBlock;
    }
  }
  output(m, n, k, min_time, base, blocksPerGrid_min, threadsPerBlock_min, "V3-3");
}



float test_kernel_prefetch4(int m, int n, int k, 
            double * dA, int lda, 
            double * dB, int ldb, 
            double * dC, int ldc,
            float base){

  float min_time = 1000;
  int blocksPerGrid_min, threadsPerBlock_min;

  for (int T = 16; T <= min(m, 1024); T*=2) {
  //int T = 128;
  int tt = 2;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < TEST_RUN; i++) {
      dgemm_kernel4_3<<<blocksPerGrid, threadsPerBlock>>>(m, n, k, T, tt, dA, lda, dB, ldb, dC, ldc);
      check_cuda_error();
    }
    cudaEventRecord(stop);

    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    float real_time = milliseconds / 1000;
    if (real_time < min_time) {
      min_time = real_time; 
      blocksPerGrid_min = blocksPerGrid;
      threadsPerBlock_min = threadsPerBlock;
    }
  }
  output(m, n, k, min_time, base, blocksPerGrid_min, threadsPerBlock_min, "V3-4");

}




float test_cublas_mm(int m, int n, int k, 
            double * dA, int lda, 
            double * dB, int ldb, 
            double * dC, int ldc);


void test(int m, int k, int c);


int main(int argc, char *argv[]){
  for (int i = 10240; i <= 40960; i += 1024){
  //int i = 1024;
    // cout << "Test on: A (" << i << " x " << i << ") by B (" << i << " x " << 2 << ")" << endl;
    test(i, i, atoi(argv[1]));
  }
}

void test(int m, int k, int c){
    cudaDeviceSetCacheConfig(cudaFuncCachePreferShared);

    //m = 16;
    int n = 16;
    //int k = 20480;
    double * A = new double[m * k];
    double * B = new double[n * k];
    double * C = new double[m * n];
    double * checkC = new double[m * n];     

    for (int i = 0; i < m * k; i++){
    	A[i] = i;
    }

    for (int i = 0; i < n * k; i++){
    	B[i] = 1;
    }
    
    double * dA;
    cudaMalloc(&dA, m * k * sizeof(double));
    int lda = m;

    double * dB; 
    cudaMalloc(&dB,  n * k * sizeof(double));
    int ldb = k;

    double * dC;
    cudaMalloc(&dC, m * n * sizeof(double));
    int ldc = m;

    double * dcheckC;
    cudaMalloc(&dcheckC, m * n * sizeof(double));

    cudaMemcpy(dA, A, m * k * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(dB, B, n * k * sizeof(double), cudaMemcpyHostToDevice);
    
    float base;

    base = test_cublas_mm(m, n, k,  dA, lda, dB, ldb, dcheckC, ldc);
    if (c == -1) cout << base << endl;
    if (c == 0) test_kernel_naive(m, n, k, dA, lda, dB, ldb, dC, ldc, base);
    if (c == 1) test_kernel_reduce_gld(m, n, k, dA, lda, dB, ldb, dC, ldc, base);
    if (c == 2) test_kernel_shared(m, n, k, dA, lda, dB, ldb, dC, ldc, base);
    // test_kernel_prefetch(m, n, k, dA, lda, dB, ldb, dC, ldc, base);
    // test_kernel_prefetch2(m, n, k, dA, lda, dB, ldb, dC, ldc, base);
    if (c == 3) test_kernel_prefetch3(m, n, k, dA, lda, dB, ldb, dC, ldc, base);
    // test_kernel_prefetch4(m, n, k, dA, lda, dB, ldb, dC, ldc, base);

    //free device memory
    cudaFree(dA);
    cudaFree(dB);
    cudaFree(dC);

    delete[] A;
    delete[] B;
    delete[] C;
    delete[] checkC;

}



float test_cublas_mm(int m, int n, int k, 
         double * dA, int lda, 
         double * dB, int ldb, 
         double * dC, int ldc){

    double one = 1;
    double zero = 0;
    cublasHandle_t handle;
    cublasCreate(&handle);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < TEST_RUN; i++)
      cublasDgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, m, n, k,
        &one, dA, lda, dB, ldb, &zero, dC, ldc);
    cudaEventRecord(stop);

    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    float real_time = milliseconds / 1000;
    // cout <<"Runing time of culasdgemm:" << real_time <<" s." << endl;

    return real_time;
}






























