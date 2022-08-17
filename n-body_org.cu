#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#define N (3)
#define dt 0.001
#define Soften (1e-6)
// #define NT 256
// #define NB (N/NT)
#define Frame 10

//加速度の計算
__global__ void kernel(float *d_x,float *d_y,
		       float *d_z,float *d_vx, float *d_vy,
		       float *d_vz,float *d_ax, float *d_ay,
		       float *d_az,float *d_m){
  int i,j;
  float rx,ry,rz;
  float dist2, dist6, invDist3,s;
  i = blockDim.x*blockIdx.x+threadIdx.x;
  for(j=0;j<N;j++){
    rx=d_x[j]-d_x[i];
    ry=d_y[j]-d_y[i];
    rz=d_z[j]-d_z[i];
    // 2天体間の距離を計算
    dist2 = rx*rx + ry*ry + rz*rz + Soften;
    // m/r^3 の計算
    dist6 = dist2*dist2*dist2;
    invDist3 = 1.0/sqrt(dist6);
    s = d_m[j]*invDist3;
    //天体jによる加速度を加算
    d_ax[i] = d_ax[i] + rx*s;
    d_ay[i] = d_ay[i] + ry*s;
    d_az[i] = d_az[i] + rz*s;
  }
}

// tで積分
__global__ void integrate(float *d_x, float *d_y, float *d_z,
			  float *d_vx, float *d_vy, float *d_vz, float *d_ax, float *d_ay, float *d_az){
  int i=blockIdx.x*blockDim.x + threadIdx.x;
  d_x[i] = d_x[i] + dt*d_vx[i];
  d_y[i] = d_y[i] + dt*d_vy[i];
  d_z[i] = d_z[i] + dt*d_vz[i];
  d_vx[i] = d_vx[i] + dt*d_ax[i];
  d_vy[i] = d_vy[i] + dt*d_ay[i];
  d_vz[i] = d_vz[i] + dt*d_az[i];
}

void initial(float *x,float *y,float *z,float *vx,float *vy,float *vz,float *m){
  int i;
  //乱数で配置を決定
  //x,y座標，x,y方向速度が‐1~1の範囲に収まるように決定
  srand(N);
  for(i=0;i<N;i++){
    x[i] = (float)rand()/RAND_MAX*2.0 - 1.0;
    y[i] = (float)rand()/RAND_MAX*2.0 - 1.0;
    z[i] = (float)rand()/RAND_MAX*2.0 - 1.0;;
    m[i] = 1.0f;
    vx[i] = (float)rand()/RAND_MAX*2.0 - 1.0;
    vy[i] = (float)rand()/RAND_MAX*2.0 - 1.0;
    vz[i] = (float)rand()/RAND_MAX*2.0 - 1.0;;
  }
}

int main(void){
  //GPUのメモリ上に確保
  float *d_x,*d_y,*d_z,*d_m;
  float *d_vx,*d_vy,*d_vz;
  float *d_ax,*d_ay,*d_az;
  cudaMallocManaged((void **)&d_x, (N*sizeof(float)));
  cudaMallocManaged((void **)&d_y, (N*sizeof(float)));
  cudaMallocManaged((void **)&d_z, (N*sizeof(float)));
  cudaMallocManaged((void **)&d_m, (N*sizeof(float)));
  cudaMallocManaged((void **)&d_vx, (N*sizeof(float)));
  cudaMallocManaged((void **)&d_vy, (N*sizeof(float)));
  cudaMallocManaged((void **)&d_vz, (N*sizeof(float)));
  cudaMalloc((void **)&d_ax, (N*sizeof(float)));
  cudaMalloc((void **)&d_ay, (N*sizeof(float)));
  cudaMalloc((void **)&d_az, (N*sizeof(float)));
  initial(d_x, d_y, d_z, d_vx, d_vy, d_vz, d_m);
  for(int t = 0; t < 10; t++){
    for (int i = 0; i < N; i++){
      printf("%lf %lf %lf\n", d_x[i], d_y[i], d_z[i]);
    }
    printf("\n\n");
    kernel<<<1,3>>>(d_x, d_y, d_z, d_vx, d_vy, d_vz, d_ax, d_ay, d_az, d_m);
    integrate<<<1,3>>>(d_x, d_y, d_z, d_vx, d_vy, d_vz, d_ax, d_ay, d_az);
    cudaDeviceSynchronize();
  }
  cudaFree(d_x);
  cudaFree(d_y);
  cudaFree(d_z);
  cudaFree(d_m);
  cudaFree(d_vx);
  cudaFree(d_vy);
  cudaFree(d_vz);
  cudaFree(d_ax);
  cudaFree(d_ay);
  cudaFree(d_az);
  cudaDeviceReset();
  return 0;
}
