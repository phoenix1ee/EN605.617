// Modification of Ingemar Ragnemalm "Real Hello World!" program
// To compile execute below:
// nvcc hello-world.cu -L /usr/local/cuda/lib -lcudart -o hello-world

//time function
#include <inttypes.h>
#include <stdint.h>
#if defined(_WIN32)
    #include <windows.h>
    uint64_t timens(void) {
        static LARGE_INTEGER freq;
        static int initialized = 0;
        if (!initialized) {
            QueryPerformanceFrequency(&freq);
            initialized = 1;
        }
        LARGE_INTEGER counter;
        QueryPerformanceCounter(&counter);
        return (uint64_t)(counter.QuadPart * 1000000000ull / freq.QuadPart);
    }
#else
    #include <time.h>
    uint64_t timens(void) {
        struct timespec ts;
        clock_gettime(CLOCK_MONOTONIC, &ts);
        return (uint64_t)ts.tv_sec * 1000000000ull + ts.tv_nsec;
    }
#endif

#include <stdio.h>

#define N 192
#define BLOCK_SIZE 512
#define NUM_BLOCKS N/BLOCK_SIZE

#define ARRAY_SIZE N
#define ARRAY_SIZE_IN_BYTES (sizeof(unsigned int) * (ARRAY_SIZE))

/* Declare  statically four arrays of ARRAY_SIZE each */
unsigned int cpu_block[ARRAY_SIZE];

__global__ 
void hello(int * block)
{
	const unsigned int thread_idx = (blockIdx.x * blockDim.x) + threadIdx.x;
	block[thread_idx] = threadIdx.x;
}

void main_sub()
{
	uint64_t average = 0;
	uint64_t start=0;
	uint64_t end=0;
	for (int i=0;i<10000;i++){
	start = timens();
	/* Declare pointers for GPU based params */
	int *gpu_block;

	cudaMalloc((void **)&gpu_block, ARRAY_SIZE_IN_BYTES);
	cudaMemcpy( gpu_block, cpu_block, ARRAY_SIZE_IN_BYTES, cudaMemcpyHostToDevice );

	/* Execute our kernel */
	hello<<<NUM_BLOCKS, BLOCK_SIZE>>>(gpu_block);

	/* Free the arrays on the GPU as now we're done with them */
	cudaMemcpy( cpu_block, gpu_block, ARRAY_SIZE_IN_BYTES, cudaMemcpyDeviceToHost );
	cudaFree(gpu_block);
	end = timens();
	average = average+end-start;
	}
	printf("used time: %" PRIu64 "\n",average);
	/* Iterate through the arrays and print */
	/*for(unsigned int i = 0; i < ARRAY_SIZE; i++)
	{
		printf("Calculated Thread: - Block: %2u\n",cpu_block[i]);
	}*/
}

int main()
{
	main_sub();

	return EXIT_SUCCESS;
}
