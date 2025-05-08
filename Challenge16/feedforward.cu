#include <cuda_runtime.h>
#include <cublas_v2.h>
#include <iostream>
#include <vector>
#include <cstdlib>
#include <chrono>
#include <fstream>

// Network & benchmark params
constexpr int BATCH = 128;
constexpr int IN    = 4;
constexpr int H     = 5;
constexpr int OUT   = 1;
constexpr int STEPS = 1000;

// CUDA error checking
#define CUDA_CHECK(call)                                                     \
  do {                                                                        \
    cudaError_t err = call;                                                   \
    if (err != cudaSuccess) {                                                 \
      std::cerr << "CUDA error: " << cudaGetErrorString(err) << "\n";         \
      std::exit(1);                                                           \
    }                                                                         \
  } while (0)

// cuBLAS error checking
#define CUBLAS_CHECK(call)                                                   \
  do {                                                                        \
    cublasStatus_t st = call;                                                \
    if (st != CUBLAS_STATUS_SUCCESS) {                                        \
      std::cerr << "cuBLAS error\n";                                          \
      std::exit(1);                                                           \
    }                                                                         \
  } while (0)

// Adds bias + ReLU in-place
__global__ void add_bias_relu(float* x, const float* bias, int rows, int cols) {
  int idx = blockIdx.x*blockDim.x + threadIdx.x;
  if (idx < rows*cols) {
    int j = idx % cols;
    float v = x[idx] + bias[j];
    x[idx] = v > 0 ? v : 0;
  }
}

int main(){
  // 1) Allocate & init host data
  std::vector<float> h_x(BATCH*IN), h_W1(IN*H), h_b1(H),
                     h_W2(H*OUT), h_b2(OUT);
  srand(0);
  auto rnd = [](float& v){ v = rand()/float(RAND_MAX)-0.5f; };
  for (auto& v : h_x)  rnd(v);
  for (auto& v : h_W1) rnd(v);
  for (auto& v : h_b1) rnd(v);
  for (auto& v : h_W2) rnd(v);
  for (auto& v : h_b2) rnd(v);

  // 2) Allocate device buffers
  float *d_x, *d_y1, *d_y2, *d_W1, *d_b1, *d_W2, *d_b2;
  CUDA_CHECK(cudaMalloc(&d_x,  BATCH*IN*sizeof(float)));
  CUDA_CHECK(cudaMalloc(&d_y1, BATCH*H*sizeof(float)));
  CUDA_CHECK(cudaMalloc(&d_y2, BATCH*OUT*sizeof(float)));
  CUDA_CHECK(cudaMalloc(&d_W1, IN*H*sizeof(float)));
  CUDA_CHECK(cudaMalloc(&d_b1, H*sizeof(float)));
  CUDA_CHECK(cudaMalloc(&d_W2, H*OUT*sizeof(float)));
  CUDA_CHECK(cudaMalloc(&d_b2, OUT*sizeof(float)));

  // 3) Copy params Host→Device
  CUDA_CHECK(cudaMemcpy(d_x,  h_x.data(),  BATCH*IN*sizeof(float),  cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_W1, h_W1.data(), IN*H*sizeof(float),    cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_b1, h_b1.data(), H*sizeof(float),      cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_W2, h_W2.data(), H*OUT*sizeof(float),   cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_b2, h_b2.data(), OUT*sizeof(float),     cudaMemcpyHostToDevice));

  // 4) cuBLAS handle
  cublasHandle_t handle;
  CUBLAS_CHECK(cublasCreate(&handle));

  // Warm-up
  const float α = 1.0f, β = 0.0f;
  CUBLAS_CHECK(cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N,
                           H, BATCH, IN, &α,
                           d_W1, H, d_x, IN, &β,
                           d_y1, H));
  add_bias_relu<<<(BATCH*H+255)/256,256>>>(d_y1, d_b1, BATCH, H);
  CUBLAS_CHECK(cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N,
                           OUT, BATCH, H, &α,
                           d_W2, OUT, d_y1, H, &β,
                           d_y2, OUT));
  cudaDeviceSynchronize();

  // Timed loop
  cudaEvent_t t0, t1;
  CUDA_CHECK(cudaEventCreate(&t0));
  CUDA_CHECK(cudaEventCreate(&t1));
  CUDA_CHECK(cudaEventRecord(t0));
  for(int i=0; i<STEPS; ++i){
    CUBLAS_CHECK(cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N,
                             H, BATCH, IN, &α,
                             d_W1, H, d_x, IN, &β,
                             d_y1, H));
    add_bias_relu<<<(BATCH*H+255)/256,256>>>(d_y1, d_b1, BATCH, H);
    CUBLAS_CHECK(cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N,
                             OUT, BATCH, H, &α,
                             d_W2, OUT, d_y1, H, &β,
                             d_y2, OUT));
  }
  CUDA_CHECK(cudaEventRecord(t1));
  CUDA_CHECK(cudaEventSynchronize(t1));

  float ms = 0.f;
  CUDA_CHECK(cudaEventElapsedTime(&ms, t0, t1));

  // Write timing to CSV
  std::ofstream fout("cuda_times.csv", std::ios::app);
  fout << "IN4_H5_OUT1," << ms << "\n";
  fout.close();
  std::cout << "Custom CUDA forward time (ms): " << ms << "\n";

  // Cleanup
  cublasDestroy(handle);
  cudaFree(d_x);  cudaFree(d_y1); cudaFree(d_y2);
  cudaFree(d_W1); cudaFree(d_b1); cudaFree(d_W2); cudaFree(d_b2);
  return 0;
}
