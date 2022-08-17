#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#define N (3)
#define dt 0.001
#define Soften 1000000
#define Frame 10

//プロトタイプ宣言

//初期値の設定
void initial(float *x,float *y,float *z,float *vx,float *vy,float *vz,float *m){
    int i;
    //乱数で配置を決定
    //x,y座標，x,y方向速度が‐1~1の範囲に収まるように決定
    srand(N);
    for(i=0;i<N;i++){
        x[i] = (float)rand()/RAND_MAX*2.0 - 1.0;
        y[i] = (float)rand()/RAND_MAX*2.0 - 1.0;
        z[i] = (float)rand()/RAND_MAX*2.0 - 1.0;
        m[i] = 1.0f;
        vx[i] = (float)rand()/RAND_MAX*2.0 - 1.0;
        vy[i] = (float)rand()/RAND_MAX*2.0 - 1.0;
        vz[i] = (float)rand()/RAND_MAX*2.0 - 1.0;
    }
}

//時間積分
void integrate(float *x, float *y, float *z,
    float *vx, float *vy, float *vz, float *ax, float *ay, float *az){
    int i;
    //Euler法で位置と速度を積分
    //必ず位置の積分を先に実行
    for(i=0;i<N;i++){
        x[i] = x[i] + dt*vx[i];
        y[i] = y[i] + dt*vy[i];
        z[i] = z[i] + dt*vz[i];
        vx[i] = vx[i] + dt*ax[i];
        vy[i] = vy[i] + dt*ay[i];
        vz[i] = vz[i] + dt*az[i];
    }
}

//加速度の計算
void kernel(float *x, float *y, float *z,
float *vx, float *vy, float *vz,
float *ax, float *ay, float *az,
float *m){
    int i,j;
    float rx,ry,rz;
    float dist2, dist6, invDist3,s;
    for(i=0;i<N;i++){
        ax[i] = 0.0f;
        ay[i] = 0.0f;
        az[i] = 0.0f;
    }
    for(i=0;i<N;i++){
        for(j=0;j<N;j++){
            //if(i==j)continue;
            rx=x[j]-x[i];
            ry=y[j]-y[i];
            rz=z[j]-z[i];
            //2天体間の距離を計算
            dist2 = rx*rx + ry*ry + rz*rz
            + Soften;//軟化パラメータ
            // m/r^3 の計算
            dist6 = dist2*dist2*dist2;
            invDist3 = 1.0/sqrt(dist6);
            s = m[j]*invDist3;
            //天体jによる加速度を加算
            ax[i] = ax[i] + rx*s;
            ay[i] = ay[i] + ry*s;
            az[i] = az[i] + rz*s;
        }
    }
}

int main(void){
    float *x,*y,*z,*m;
    float *vx,*vy,*vz;
    float *ax,*ay,*az;
    x = (float *)malloc(N*sizeof(float));
    y = (float *)malloc(N*sizeof(float));
    z = (float *)malloc(N*sizeof(float));
    m = (float *)malloc(N*sizeof(float));
    vx = (float *)malloc(N*sizeof(float));
    vy = (float *)malloc(N*sizeof(float));
    vz = (float *)malloc(N*sizeof(float));
    ax = (float *)malloc(N*sizeof(float));
    ay = (float *)malloc(N*sizeof(float));
    az = (float *)malloc(N*sizeof(float));
    //初期値設定
    initial(x,y,z,vx,vy,vz,m);
    for(int t = 0; t < Frame; t++){ //本来なら必要な回数だけ繰り返す
        for (int i = 0; i < N; i++){
            printf("%lf %lf %lf\n", x[i], y[i], z[i]);
        }
        printf("\n\n");
    //加速度の計算
        kernel(x,y,z,vx,vy,vz,ax,ay,az,m);
    //時間積分
        integrate(x,y,z,vx,vy,vz,ax,ay,az);
    }
    return 0;
}
