#include <stdlib.h>
#include <iostream>
#include "cublas_v2.h"
#include <cmath>
#include <time.h>
#include <stdio.h>
#include <string>
#include <stdlib.h>
#define TEST_RUN 10 
#define ESP 10e-10
#define PEAK_MEM 900
using namespace std;


void check_cuda_error(){
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess)
    printf("Error: %s\n", cudaGetErrorString(err));
}

void check_C(float * dC, int m, int n, float * checkC) {
  for (int i = 0; i < m * n; i++){
    //cout << i << endl;
    if (fabs(dC[i] - checkC[i]) > ESP){
      cout << "error:" << fabs(dC[i] - checkC[i]) << endl;
      return;
    }
  }
  cout << "correct" << endl;
}

void output(int m, int n, int k, float min_time, float base, int blocksPerGrid_min, int threadsPerBlock_min, string func) {
  // long long total_bytes = (m * k + k * n * (k / 32)) * sizeof(double);
  long long total_bytes = (m * k + k * n * blocksPerGrid_min) * sizeof(float);
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
dgemm_kernel_naive(int m, int n, int k, float * A, int lda, float * B, int ldb, float * C, int ldc)
{
  //determine the row to process                                                        
  register int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  register float a = 0;
  register float b = 0;
  register float temp = 0;
 
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
dgemm_kernel_reduce_gld(int m, int n, int k, float * A, int lda, float * B, int ldb, float * C, int ldc)
{
  //determine the row to process                                                        
  register int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  register float temp1 = 0;
  register float temp2 = 0;
  register float a = 0;
  register float b1 = 0;
  register float b2 = 0;

  #pragma unroll 1
  for (int i = 0; i < k; i+=1){
    //load data
    a = *A;
    b1 = *B;
    b2 = *(B + ldb);
    A += lda;
    B += 1;

    //compute
    temp1 = temp1 + a * b1;
    temp2 = temp2 + a * b2;

  }

  *(C + 0 * ldc + idx) = temp1;
  *(C + 1 * ldc + idx) = temp2;
  
}


void test_kernel_naive(int m, int n, int k, 
            float * dA, int lda, 
            float * dB, int ldb, 
            float * dC, int ldc,
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
            float * dA, int lda, 
            float * dB, int ldb, 
            float * dC, int ldc,
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
dgemm_kernel_shared(int m, int n, int k, int T, float * A, int lda, float * B, int ldb, float * C, int ldc)
{
  // store B (T * 2)
  extern __shared__ float cache[];
  
  //determine the row to process
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  register float temp1 = 0;
  register float temp2 = 0;
  register float a = 0;

  for (int j = 0; j < k; j += T){
    cache[threadIdx.x * 2] = *(B + threadIdx.x);
    cache[threadIdx.x * 2 + 1] = *(B + threadIdx.x + ldb);
    __syncthreads();
    B += T;
    for (int i = 0; i < T; i++) {
      a = *(A + (i + j) * lda);
      temp1 += a * cache[i * 2];
      temp2 += a * cache[i * 2 + 1];
    }
    __syncthreads();

  }
  *(C + 0 * ldc + idx) = temp1;
  *(C + 1 * ldc + idx) = temp2;

}


float test_kernel_shared(int m, int n, int k, 
          float * dA, int lda, 
          float * dB, int ldb, 
          float * dC, int ldc,
          float base){

  float min_time = 1000;
  int blocksPerGrid_min, threadsPerBlock_min;
  for (int T = 16; T <= min(1024, m); T *= 2) {

    //int T = 16;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;
    
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < TEST_RUN; i++)
      dgemm_kernel_shared<<<blocksPerGrid, threadsPerBlock,  T * sizeof(float) * 2>>>(m, n, k, T, dA, lda, dB, ldb, dC, ldc);
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
dgemm_kernel_prefetch_s2r_16(int m, int n, int k, int T, float * A, int lda, float * B, int ldb, float * C, int ldc)
{

  extern __shared__ float cache[];
  
  float * cacheA = cache;
  float * cacheB = cache + T * T;
  
  //determine the row to process
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  float temp1 = 0;
  float temp2 = 0;

//prefectch A
  for (int i = 0; i < T; i++){
    cacheA[threadIdx.x + i * T] = *(A + i * lda);
  }
  
  float r0, r1, r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15;

  for (int j = 0; j < k; j += T){
    
    __syncthreads();
    cacheB[threadIdx.x * 2] = *(B + threadIdx.x);
    cacheB[threadIdx.x * 2 + 1] = *(B + threadIdx.x + ldb);
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
      temp1 += cacheA[threadIdx.x +i * T] * cacheB[i * 2];
      temp2 += cacheA[threadIdx.x +i * T] * cacheB[i * 2 + 1];
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

}


__global__ void
dgemm_kernel_prefetch_s2r_8(int m, int n, int k, int T, float * A, int lda, float * B, int ldb, float * C, int ldc)
{

  extern __shared__ float cache[];
  
  float * cacheA = cache;
  float * cacheB = cache + T * T;
  
  //determine the row to process
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  float temp1 = 0;
  float temp2 = 0;

//prefectch A
  for (int i = 0; i < T; i++){
    cacheA[threadIdx.x + i * T] = *(A + i * lda);
  }
  
  float r0, r1, r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15;

  for (int j = 0; j < k; j += T){
    
    __syncthreads();
    cacheB[threadIdx.x * 2] = *(B + threadIdx.x);
    cacheB[threadIdx.x * 2 + 1] = *(B + threadIdx.x + ldb);
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
      temp1 += cacheA[threadIdx.x +i * T] * cacheB[i * 2];
      temp2 += cacheA[threadIdx.x +i * T] * cacheB[i * 2 + 1];
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

}


void test_kernel_prefetch(int m, int n, int k, 
            float * dA, int lda, 
            float * dB, int ldb, 
            float * dC, int ldc,
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
        dgemm_kernel_prefetch_s2r_16<<<blocksPerGrid, threadsPerBlock, ((T * 2) + (T * T)) * sizeof(float)>>>(m, n, k, T, dA, lda, dB, ldb, dC, ldc);
      else if (T == 8)
        dgemm_kernel_prefetch_s2r_8<<<blocksPerGrid, threadsPerBlock, ((T * 2) + (T * T)) * sizeof(float)>>>(m, n, k, T, dA, lda, dB, ldb, dC, ldc);
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
//Shared mem.: T*2 + T*T (float)
__global__ void
dgemm_kernel_prefetch_s2r_4_16(int m, int n, int k, int T, int t, float * A, int lda, float * B, int ldb, float * C, int ldc)
{
  // store B (T * 2)                                                                                                                                                                                                                                                                       
  extern __shared__ float cache[];
 
  float * cacheA = cache;
  float * cacheB = cache + T * t; //32 threads * 8 elements

  //determine the row to process                                                                                                                                                                                                                                                           
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  float temp1 = 0;
  float temp2 = 0;

  #pragma unroll 1
  //prefectch A 
  for (int i = 0; i < t; i++){
    cacheA[threadIdx.x + i * T] = *(A + i * lda);
  }
  A += t * lda;

  float r0, r1, r2, r3;

  #pragma unroll 1
  for (int j = 0; j < k; j += T){ 
    __syncthreads();
    cacheB[threadIdx.x * 2] = *(B + threadIdx.x);
    cacheB[threadIdx.x * 2 + 1] = *(B + threadIdx.x + ldb);
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
    
}

void test_kernel_prefetch2(int m, int n, int k, 
            float * dA, int lda, 
            float * dB, int ldb, 
            float * dC, int ldc,
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
      dgemm_kernel_prefetch_s2r_4_16<<<blocksPerGrid, threadsPerBlock, ((T * 2) + (T * tt)) * sizeof(float)>>>(m, n, k, T, tt, dA, lda, dB, ldb, dC, ldc);
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
//Shared mem.: T*2 + T*T (float)
//#define t 4
__global__ void
dgemm_kernel4_2(int m, int n, int k, int T, int t, float * A, int lda, float * B, int ldb, float * C, int ldc)
{
  // store B (T * 2)                                                                                                                                                                                                                                                                       
  extern __shared__ float cacheB[];

  //determine the row to process                                                                                                                                                                                                                          
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  C = C + idx;
  register float temp1 = 0;
  register float temp2 = 0;

  register float nr0, nr1, nr2, nr3;
  register float cr0, cr1, cr2, cr3;

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
    cacheB[threadIdx.x * 2] = *(B + threadIdx.x);
    cacheB[threadIdx.x * 2 + 1] = *(B + threadIdx.x + ldb);
    // if (j == 0 && idx == 0)
    //   printf("%f %f \n", *(B + threadIdx.x), *(B + threadIdx.x + ldb));
    __syncthreads();
    B += T;

    #pragma unroll 1
    for (int l = j; l < j + T; l += 4){
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

      // if (j == 0 && idx == 0){
      //   printf("%f %f \n",  cacheB[(l - j) * 2 + 0 ], cacheB[(l - j) * 2 + 1]);
      //   printf("%f %f %f %f\n",  cr0, cr1, cr2 ,cr3);
      // }


      temp1 += cr0 * cacheB[(l - j) * 2 + 0 ];
      temp2 += cr0 * cacheB[(l - j) * 2 + 1];



      temp1 += cr1 * cacheB[(l - j) * 2 + 2 ];
      temp2 += cr1 * cacheB[(l - j) * 2 + 3];

     temp1 += cr2 * cacheB[(l - j) * 2 + 4 ];
     temp2 += cr2 * cacheB[(l - j) * 2 + 5];

     temp1 += cr3 * cacheB[(l - j) * 2 + 6];
     temp2 += cr3 * cacheB[(l - j) * 2 + 7];

   //   if (l + t < k) {
        cr0 = nr0;
        cr1 = nr1;
        cr2 = nr2;
        cr3 = nr3;
   //   }
    }
  }
  *C = temp1;
  *(C + ldc) = temp2;
    
}


//Single registers: m, n, k, T, t, lda, ldb, ldc, idx, j, l (11)
//Double registers: cacheB, A, B, C, nr0-3, cr0-3, temp1-2 (28)
//Shared mem.: T*2 + T*T (float)
__global__ void
dgemm_kernel4_3(int m, int n, int k, int T, int t, float * A, int lda, float * B, int ldb, float * C, int ldc)
{
                                                                                                                                                                                                                
  // //determine the row to process                                                                                                                                                                                                                          
  // int idx = blockIdx.x * blockDim.x + threadIdx.x;
  // A = A + idx;
  // C = C + idx;
  // register float temp1 = 0;
  // register float temp2 = 0;

  // register float nr0, nr1, nr2, nr3;
  // register float cr0, cr1, cr2, cr3;

  // register float nb00, nb01, nb10, nb11;
  // register float cb00, cb01, cb10, cb11;

  // //prefectch A 
  // cr0 = *A;
  // A += lda;
  // cr1 = *A;
  // A += lda;
  
  // cr2 = *A;
  // A += lda;
  // cr3 = *A;
  // A += lda;

  // cb00 = *B;
  // cb01 = *(B + ldb);
  // B += 1;
  // cb10 = *B;
  // cb11 = *(B + ldb);
  // B += 1;


  // #pragma unroll 1
  // for (int i = 0; i < k; i += t){ 
  //     if (i + t < k) {
  //       nr0 = *A;
  //       A += lda;
  //       nr1 = *A;
  //       A += lda;

  //       nr2 = *A;
  //       A += lda;
  //       nr3 = *A;
  //       A += lda;
  //     }
      
  //     //temp1 += cr1 * cr1;
  //     //temp2 += cr2 * cr2;
  //     //temp1 += cr3 * cr3;
  //     //temp1 += cr0 * cr0;
      
  //     nb00 = *B;
  //     nb01 = *(B + ldb);
  //     B += 1;
  //     nb10 = *B;
  //     nb11 = *(B + ldb);
  //     B += 1;

  //     temp1 += cr0 * cb00;
  //     temp2 += cr0 * cb01;
  //     temp1 += cr1 * cb10;
  //     temp2 += cr1 * cb11;

  //     cb00 = nb00;
  //     cb01 = nb01;
  //     cb10 = nb10;
  //     cb11 = nb11;


  //     if (i + t < k) {
  //       nb00 = *B;
  //       nb01 = *(B + ldb);
  //       B += 1;
  //       nb10 = *B;
  //       nb11 = *(B + ldb);
  //       B += 1;
  //     }

  //     temp1 += cr2 * cb00;
  //     temp2 += cr2 * cb01;
  //     temp1 += cr3 * cb10;
  //     temp2 += cr3 * cb11;

  //     cb00 = nb00;
  //     cb01 = nb01;
  //     cb10 = nb10;
  //     cb11 = nb11;
    
      
  //     if (i + t < k) {
  //       cr0 = nr0;
  //       cr1 = nr1;
  //       cr2 = nr2;
  //       cr3 = nr3;
  //     }
      
  // }
  // *C = temp1;
  // *(C + ldc) = temp2;
    
}


float test_kernel_prefetch3(int m, int n, int k, 
            float * dA, int lda, 
            float * dB, int ldb, 
            float * dC, int ldc,
            float base){

  float min_time = 1000;
  int blocksPerGrid_min, threadsPerBlock_min;
  for (int T = 4; T <= min(m, 1024); T*=2) {
 
    int tt = 4;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < TEST_RUN; i++) {
      dgemm_kernel4_2<<<blocksPerGrid, threadsPerBlock, ((T * 2)) * sizeof(float)>>>(m, n, k, T, tt, dA, lda, dB, ldb, dC, ldc);
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
            float * dA, int lda, 
            float * dB, int ldb, 
            float * dC, int ldc,
            float base){

  float min_time = 1000;
  int blocksPerGrid_min, threadsPerBlock_min;
  for (int T = 16; T <= min(m, 1024); T*=2) {
  //int T = 128;
  int tt = 4;
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
            float * dA, int lda, 
            float * dB, int ldb, 
            float * dC, int ldc);


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

    //int m = 20480;
    int n = 2;
    //int k = 20480;
    float * A = new float[m * k];
    float * B = new float[n * k];
    float * C = new float[m * n];
    float * checkC = new float[m * n];     

    for (int i = 0; i < m * k; i++){
    	A[i] = (float)i/(m * k);
    }

    for (int i = 0; i < n * k; i++){
    	B[i] = (float)i/(n * k);
    }
    
    float * dA;
    cudaMalloc(&dA, m * k * sizeof(float));
    int lda = m;

    float * dB; 
    cudaMalloc(&dB,  n * k * sizeof(float));
    int ldb = k;

    float * dC;
    cudaMalloc(&dC, m * n * sizeof(float));
    int ldc = m;

    float * dcheckC;
    cudaMalloc(&dcheckC, m * n * sizeof(float));

    cudaMemcpy(dA, A, m * k * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(dB, B, n * k * sizeof(float), cudaMemcpyHostToDevice);
    
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
    
   
    // cudaMemcpy(C, dC ,m * n * sizeof(float), cudaMemcpyDeviceToHost);
    // cudaMemcpy(checkC, dcheckC, m * n * sizeof(float), cudaMemcpyDeviceToHost);
    // //for (int i = 0; i < m * n; i++){
    // // cout<<C[i]<<" ";	
    // //}
    // check_C(C, m, n, checkC);

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
         float * dA, int lda, 
         float * dB, int ldb, 
         float * dC, int ldc){

    float one = 1;
    float zero = 0;
    cublasHandle_t handle;
    cublasCreate(&handle);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < TEST_RUN; i++)
      cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, m, n, k,
        &one, dA, lda, dB, ldb, &zero, dC, ldc);
    cudaEventRecord(stop);

    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    float real_time = milliseconds / 1000;

    // cout <<"Runing time of culasdgemm:" << real_time <<" s." << endl;
    return real_time;
}






























