#include <stdlib.h>
#include <iostream>
#include "cublas_v2.h"
#include <time.h>
#include <stdio.h>
#include <cmath>
#define TEST_RUN 100
#define ESP 10e-10
using namespace std;


__global__ void
dgemm_kernel2(int m, int n, int k, 
			  double * A, int lda, 
			  double * B, int ldb, 
			  double * C, int ldc);

__global__ void
dgemm_kernel2_sass(int m, int n, int k,
	      double * A, int lda,
	      double * B, int ldb,
	      double * C, int ldc);

__global__ void
dgemm_kernel2_1(int m, int n, int k, 
				double * A, int lda, 
				double * B, int ldb, 
				double * C, int ldc);

__global__ void
dgemm_kernel3(int m, int n, int k, int T, 
			  double * A, int lda, 
			  double * B, int ldb, 
			  double * C, int ldc);

__global__ void
dgemm_kernel4(int m, int n, int k, int T, 
			  double * A, int lda, 
			  double * B, int ldb, 
			  double * C, int ldc);

__global__ void
dgemm_kernel4_1(int m, int n, int k, int T, int t,
				double * A, int lda, 
				double * B, int ldb, 
				double * C, int ldc);

__global__ void
dgemm_kernel4_2(int m, int n, int k, int T, int t, 
				double * A, int lda, 
				double * B, int ldb, 
				double * C, int ldc);

__global__ void
dgemm_kernel4_3(int m, int n, int k, int T, int t, 
				double * A, int lda, 
				double * B, int ldb, 
				double * C, int ldc);

void check_C(double * dC, int m, double * checkC);

void test_cublas_mv(int m, int n, int k, 
				    double * dA, int lda, 
				    double * dB, int ldb, 
				    double * dC, int ldc);

void test_cublas_mm(int m, int n, int k, 
				    double * dA, int lda, 
				    double * dB, int ldb, 
				    double * dC, int ldc);

void test_kernel2(int m, int n, int k, 
				  double * dA, int lda, 
				  double * dB, int ldb, 
				  double * dC, int ldc);

void test_kernel2_sass(int m, int n, int k, 
          double * dA, int lda, 
          double * dB, int ldb, 
          double * dC, int ldc);

void test_kernel2_1(int m, int n, int k, 
				    double * dA, int lda, 
				    double * dB, int ldb, 
				    double * dC, int ldc);

void test_kernel3(int m, int n, int k, 
				  double * dA, int lda, 
				  double * dB, int ldb, 
				  double * dC, int ldc);

void test_kernel4(int m, int n, int k, 
				  double * dA, int lda, 
				  double * dB, int ldb, 
				  double * dC, int ldc);

void test_kernel4_1(int m, int n, int k, 
				  double * dA, int lda, 
				  double * dB, int ldb, 
				  double * dC, int ldc);

void test_kernel4_2(int m, int n, int k, 
				  double * dA, int lda, 
				  double * dB, int ldb, 
				  double * dC, int ldc);

void test_kernel4_3(int m, int n, int k, 
				  double * dA, int lda, 
				  double * dB, int ldb, 
				  double * dC, int ldc);

void test(int m, int k);

int main(){
	for (int i = 128; i <= 32768; i *= 2){
		//i = 20480;
		cout << "Test on: A (" << i << " x " << i << ") by B (" << i << " x " << 1 << ")" << endl;
		test(i, i);
	}
}

void test(int m, int k){
  cudaDeviceSetCacheConfig(cudaFuncCachePreferShared);

    //int m = 20480;
    int n = 1;
    //int k = 20480;
    double * A = new double[m * k];
    double * B = new double[n * k];
    double * C = new double[m * n];  
    double * checkC = new double[m * n];   

    for (int i = 0;i < m * k; i++){
    	A[i] = i;
    }

    //    for (int i = 0; i < m; i++){
    // for (int j = 0; j < k; j++){
    //	cout << *( A + i + j * m) << " ";
    // }
    // cout << endl;
    //}
    
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
    
   

    test_cublas_mm(m, n, k,  dA, lda, dB, ldb, dcheckC, ldc);
    test_cublas_mv(m, n, k, dA, lda, dB, ldb,  dC, ldc);
    //test_kernel2(m, n, k, dA, lda, dB, ldb, dC, ldc);
    //test_kernel2_sass(m, n, k, dA, lda, dB, ldb, dC, ldc);
    //test_kernel2_1(m, n, k, dA, lda, dB, ldb, dC, ldc);
    //test_kernel3(m, n, k, dA, lda, dB, ldb, dC, ldc);
    //test_kernel4(m, n, k, dA, lda, dB, ldb, dC, ldc);
    //test_kernel4_1(m, n, k, dA, lda, dB, ldb, dC, ldc);
    //test_kernel4_2(m, n, k, dA, lda, dB, ldb, dC, ldc);
    test_kernel4_3(m, n, k, dA, lda, dB, ldb, dC, ldc);
    


   
    cudaMemcpy(C, dC, m * n * sizeof(double), cudaMemcpyDeviceToHost);
    cudaMemcpy(checkC, dcheckC, m * n * sizeof(double), cudaMemcpyDeviceToHost);

    check_C(C, m, checkC);    
    
    //for (int i = 0; i < m * n; i++){
    // cout<<C[i]<<" ";	
    //}
    
    //free device memory
    cudaFree(dA);
    cudaFree(dB);
    cudaFree(dC);

    delete[] A;
    delete[] B;
    delete[] C;
    delete[] checkC;

}


void test_cublas_mv(int m, int n, int k, 
				 double * dA, int lda, 
				 double * dB, int ldb, 
				 double * dC, int ldc){
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);


    double one = 1;
    double zero = 0;
    cublasHandle_t handle;
    cublasCreate(&handle);


    int incb = 1;
    clock_t t = clock();
    for (int i = 0; i < TEST_RUN; i++)
      cublasDgemv(handle, CUBLAS_OP_N, m, k,
      			  &one, dA, lda, dB, incb, &zero, dC, incb);

    cudaDeviceSynchronize();
    t = clock() - t;
    float real_time = ((float)t)/CLOCKS_PER_SEC;

    cout <<"Runing time of culasdgemv:" << real_time <<" ms." << endl;

}


void test_cublas_mm(int m, int n, int k, 
				 double * dA, int lda, 
				 double * dB, int ldb, 
				 double * dC, int ldc){

    double one = 1;
    double zero = 0;
    cublasHandle_t handle;
    cublasCreate(&handle);

 
    int incb = 1;

    clock_t t = clock();
    for (int i = 0; i < TEST_RUN; i++)
      cublasDgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, m, n, k,
	  	  &one, dA, lda, dB, ldb, &zero, dC, ldc);


    cudaDeviceSynchronize();
    t = clock() - t;
    float real_time = ((float)t)/CLOCKS_PER_SEC;

    cout <<"Runing time of culasdgemm:" << real_time <<" ms." << endl;
}

void test_kernel2(int m, int n, int k, 
				  double * dA, int lda, 
				  double * dB, int ldb, 
				  double * dC, int ldc){


    int T = 128;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;
    
    clock_t t = clock();

    for (int i = 0; i < TEST_RUN; i++)
      dgemm_kernel2<<<blocksPerGrid, threadsPerBlock>>>(m, n, k, 
							dA, lda, dB, ldb, dC, ldc);


    cudaDeviceSynchronize();
    t = clock() - t;
    float real_time = ((float)t)/CLOCKS_PER_SEC;
    
    
    float mem_access = (2*m*n*sizeof(double)*TEST_RUN)/1e9;
   
    cout <<"Runing time of dgemm_kernel2: " << real_time << " ms." <<endl;    
    
} 

void test_kernel2_sass(int m, int n, int k, 
          double * dA, int lda, 
          double * dB, int ldb, 
          double * dC, int ldc){


    int T = 128;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;
    
    clock_t t = clock();

    for (int i = 0; i < TEST_RUN; i++)
      dgemm_kernel2_sass<<<blocksPerGrid, threadsPerBlock>>>(m, n, k, 
              dA, lda, dB, ldb, dC, ldc);


    cudaDeviceSynchronize();
    t = clock() - t;
    float real_time = ((float)t)/CLOCKS_PER_SEC;

    cout <<"Runing time of dgemm_kernel2_sass: " << real_time << " ms." << endl;    

} 


void test_kernel2_1(int m, int n, int k, 
				    double * dA, int lda, 
				    double * dB, int ldb, 
				    double * dC, int ldc){
	


	int T = 128;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;

    clock_t t = clock(); 
    for (int i = 0; i < TEST_RUN; i++)
      dgemm_kernel2_1<<<blocksPerGrid, threadsPerBlock>>>(m, n, k,
    						  dA, lda, dB, ldb, dC, ldc);


    cudaDeviceSynchronize();
    t = clock() - t;
    float real_time = ((float)t)/CLOCKS_PER_SEC;

    cout <<"Runing time of dgemm_kernel2_1: " << real_time << " ms." << endl;


}

void test_kernel3(int m, int n, int k, 
				  double * dA, int lda, 
				  double * dB, int ldb, 
				  double * dC, int ldc){

    int T = 16;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;
    
    clock_t t = clock();
    for (int i = 0; i < TEST_RUN; i++)
      dgemm_kernel3<<<blocksPerGrid, threadsPerBlock,  T * sizeof(double)>>>(m, n, k, T, dA, lda, dB, ldb, dC, ldc);
    cudaDeviceSynchronize();
    t = clock() - t;

    float real_time = ((float)t)/CLOCKS_PER_SEC;
    cout <<"Runing time of dgemm_kernel3: " << real_time << " ms." << endl;	    
}


void test_kernel4(int m, int n, int k, 
				    double * dA, int lda, 
				    double * dB, int ldb, 
				    double * dC, int ldc){

    int T = 16;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;

    clock_t t = clock();
    for (int i = 0; i < TEST_RUN; i++) {
      dgemm_kernel4<<<blocksPerGrid, threadsPerBlock, ((T) + (T * T)) * sizeof(double)>>>(m, n, k, T, dA, lda, dB, ldb, dC, ldc);
    }
    cudaDeviceSynchronize();
    t = clock() - t;
    float real_time = ((float)t)/CLOCKS_PER_SEC;
    cout <<"Runing time of dgemm_kernel4: " << real_time << " ms." << endl;    
}

void test_kernel4_1(int m, int n, int k, 
				    double * dA, int lda, 
				    double * dB, int ldb, 
				    double * dC, int ldc){    
    int T = 64;
    int tt = 4;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;

    clock_t t = clock();
    for (int i = 0; i < TEST_RUN; i++)
      dgemm_kernel4_1<<<blocksPerGrid, threadsPerBlock, ((T) + (T * tt)) * sizeof(double)>>>(m, n, k, T, tt, dA, lda, dB, ldb, dC, ldc);
    

    cudaDeviceSynchronize();
    t = clock() - t;
    float real_time = ((float)t)/CLOCKS_PER_SEC;


    cout <<"Runing time of dgemm_kernel4_1: " << real_time << " ms." << endl;	  

}


void test_kernel4_2(int m, int n, int k, 
				    double * dA, int lda, 
				    double * dB, int ldb, 
				    double * dC, int ldc){    
    int T = 64;
    int tt = 4;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;

    clock_t t = clock();
    for (int i = 0; i < TEST_RUN; i++)
      dgemm_kernel4_2<<<blocksPerGrid, threadsPerBlock, (T * tt) * sizeof(double)>>>(m, n, k, T, tt, dA, lda, dB, ldb, dC, ldc);
    

    cudaDeviceSynchronize();
    t = clock() - t;
    float real_time = ((float)t)/CLOCKS_PER_SEC;


    cout <<"Runing time of dgemm_kernel4_2: " << real_time << " ms." << endl;	  

}


void test_kernel4_3(int m, int n, int k, 
				    double * dA, int lda, 
				    double * dB, int ldb, 
				    double * dC, int ldc){    
    int T = 64;
    int tt = 4;
    int blocksPerGrid = m / T;
    int threadsPerBlock = T;

    clock_t t = clock();
    for (int i = 0; i < TEST_RUN; i++)
      dgemm_kernel4_3<<<blocksPerGrid, threadsPerBlock, ((T) + (T * tt)) * sizeof(double)>>>(m, n, k, T, tt, dA, lda, dB, ldb, dC, ldc);
    

    cudaDeviceSynchronize();
    t = clock() - t;
    float real_time = ((float)t)/CLOCKS_PER_SEC;


    cout <<"Runing time of dgemm_kernel4_3: " << real_time << " ms." << endl;	  

}

void check_C(double * dC, int m, double * checkC) {
	for (int i = 0; i < m; i++){
		if (fabs(dC[i] - checkC[i]) > ESP){
			cout << "error:" << fabs(dC[i] - checkC[i]) << endl;
			return;
		}
	}
	cout << "correct" << endl;
}


__global__ void
dgemm_kernel2(int m, int n, int k, double * A, int lda, double * B, int ldb, double * C, int ldc)
{

        
	//determine the row to process
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	A = A + idx;
	double a;
	double b;
	double temp = 0;
	for (int i = 0;i < k; i++){
	  a = *(A + i * lda);
	  b = *(B + i);
	  temp = temp + a * b;
	}
	 *(C + idx) = temp;
	
}

__global__ void
dgemm_kernel2_sass(int m, int n, int k, double * A, int lda, double * B, int ldb, double * C, int ldc)
{
  //determine the row to process                                                                                                   
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  register double a;
  register double b;
  register double * AA =A;
  register double * BB = B;
  register double temp = 0;
  register long long int lda1 = lda * 8;
  for (int i = 0;i < k; i++){
    asm volatile ("{\n\t"
		  "ld.global.f64 %0, [%2];\n\t"
		  "ld.global.f64 %1, [%3];\n\t"
		  "fma.rz.f64 %4,%0,%1,%4;\n\t"
		  "add.u64 %2, %2, %5;\n\t"
		  "add.u64 %3, %3, 0x8;\n\t"
		  "}"
		  : "+d"(a), "+d"(b), "+l"(AA), "+l"(BB),
		    "+d"(temp):"l"(lda1)
		 );
  }
  *(C + idx) = temp;

}


__global__ void
dgemm_kernel2_1(int m, int n, int k, double * A, int lda, double * B, int ldb, double * C, int ldc)
{
  //determine the row to process                                                        
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  double temp = 0;
  double a = 0;
  double b = 0;
  for (int i = 0; i < k; i++){
    a = *(A + i * lda);
    b = *(B + i);
    temp += a * b;
  }
  *(C + idx) = temp;
}

__global__ void
dgemm_kernel3(int m, int n, int k, int T, double * A, int lda, double * B, int ldb, double * C, int ldc)
{
  // store B (T * 2)
  extern __shared__ double cache[];
  
  //determine the row to process
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  double temp1 = 0;
  
  double a = 0;
  for (int j = 0; j < k; j += T){
    cache[threadIdx.x] = *(B + threadIdx.x);
    B += T;
    __syncthreads();
    for (int i = 0; i < T; i++) {
      a = *(A + (i + j) * lda);
      temp1 += a * cache[i];
    }
    __syncthreads();

  }
  *(C + idx) = temp1;
}

__global__ void
dgemm_kernel4(int m, int n, int k, int T, double * A, int lda, double * B, int ldb, double * C, int ldc)
{
  extern __shared__ double cache[];
  
  double * cacheA = cache;
  double * cacheB = cache + T * T;
  
  //determine the row to process
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  A = A + idx;
  double temp1 = 0;
                                                                                                                                                                                      
  //prefectch A
  for (int i = 0; i < T; i++){
    cacheA[threadIdx.x + i * T] = *(A + i * lda);
  }
 
  double r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15;

  for (int j = 0; j < k; j += T){
    __syncthreads();
    cacheB[threadIdx.x] = *(B + threadIdx.x);
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
      temp1 += cacheA[threadIdx.x + i * T] * cacheB[i];
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

  *(C + idx) = temp1;
}




__global__ void
dgemm_kernel4_1(int m, int n, int k, int T, int t, double * A, int lda, double * B, int ldb, double * C, int ldc)
{
  extern __shared__ double cache[];
 
  double * cacheA = cache;
  double * cacheB = cache + T * t; 

  //determine the row to process                                              
  A = A + blockIdx.x * blockDim.x + threadIdx.x;
  C = C + blockIdx.x * blockDim.x + threadIdx.x;
  double temp = 0;
                                                                                                                                                                                                                                                                        
  //prefectch A 
  for (int i = 0; i < t; i++){
    cacheA[threadIdx.x + i * T] = *(A + i * lda);
  }
  A += t * lda;
  double r0, r1, r2,r3;//, r4,r5,r6,r7;

  for (int j = 0; j < k; j += T){ 
    __syncthreads();
    cacheB[threadIdx.x] = *(B + threadIdx.x);
    __syncthreads();
    B += T;
    
    for (int l = j; l < j + T; l += t){
      if (l + t < k) {
	      r0 = *(A + 0 *lda);
	      r1 = *(A + 1 *lda);
	      r2 = *(A + 2 *lda);
	      r3 = *(A + 3 *lda); 
	  }
      
      for (int i = 0; i < t; i++) {
	       temp += cacheA[threadIdx.x + i * T] * cacheB[l - j + i ];
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
  *C= temp;
    
}



__global__ void
dgemm_kernel4_2(int m, int n, int k, int T, int t, double * A, int lda, double * B, int ldb, double * C, int ldc)
{
	extern __shared__ double cache[];

	double * cacheA = cache;

	//determine the row to process                                              
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	A = A + idx;
	double temp = 0;
	                                                                                                                                                                                                                                                                    
	//prefectch A 
	for (int i = 0; i < t; i++){
	cacheA[threadIdx.x + i * T] = *(A + i * lda);
	}
	A += t * lda;
	double r0, r1, r2,r3;//, r4,r5,r6,r7;
    
	for (int l = 0; l < k; l += t){
	  if (l + t < k) {
	      r0 = *(A + 0 *lda);
	      r1 = *(A + 1 *lda);
	      r2 = *(A + 2 *lda);
	      r3 = *(A + 3 *lda); 
	  }
	  
	  for (int i = 0; i < t; i++) {
	       temp += cacheA[threadIdx.x + i * T] * B[l + i];
	  }
	  if (l + t < k) {
	  	cacheA[threadIdx.x + 0 * T] = r0;
	  	cacheA[threadIdx.x + 1 * T] = r1;
	  	cacheA[threadIdx.x + 2 * T] = r2;
	  	cacheA[threadIdx.x + 3 * T] = r3;
	  }
	  A += t * lda;
	}
  	*(C + idx) = temp;
    
}


__global__ void
dgemm_kernel4_3(int m, int n, int k, int T, int t, double * A, int lda, double * B, int ldb, double * C, int ldc)
{
  extern __shared__ double cache[];
 
  double * cacheA = cache;
  double * cacheB = cache + T * t; 

  //determine the row to process                                              
  A = A + blockIdx.x * blockDim.x + threadIdx.x;
  C = C + blockIdx.x * blockDim.x + threadIdx.x;
  double temp = 0;
                                                                                                                                                                                                                                                                        
  //prefectch A 
  for (int i = 0; i < t; i++){
    cacheA[threadIdx.x + i * T] = *(A + i * lda);
  }
  A += t * lda;
  double r0, r1, r2,r3;//, r4,r5,r6,r7;
  double rb;
  cacheB[threadIdx.x] = *(B + threadIdx.x);

  for (int j = 0; j < k; j += T){ 
  	B += T;
    rb = *(B + threadIdx.x);  
    for (int l = j; l < j + T; l += t){
      if (l + t < k) {
	      r0 = *(A + 0 *lda);
	      r1 = *(A + 1 *lda);
	      r2 = *(A + 2 *lda);
	      r3 = *(A + 3 *lda); 
	  }
      
      for (int i = 0; i < t; i++) {
	       temp += cacheA[threadIdx.x + i * T] * cacheB[l - j + i ];
      }
      if (l + t < k) {
      	cacheA[threadIdx.x + 0 * T] = r0;
      	cacheA[threadIdx.x + 1 * T] = r1;
      	cacheA[threadIdx.x + 2 * T] = r2;
      	cacheA[threadIdx.x + 3 * T] = r3;
      }
      A += t * lda;
    }
    __syncthreads();
    cacheB[threadIdx.x] = rb;
    __syncthreads();


  }
  *C = temp;
    
}

