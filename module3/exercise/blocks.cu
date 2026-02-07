//time function
#include <iostream>
#include <chrono>
// For PRIu64
#include <cinttypes>

// Returns the count in nanoseconds as a 64-bit unsigned integer
uint64_t get_nanos(std::chrono::steady_clock::time_point start) {
    auto end = std::chrono::steady_clock::now();
    
    // Get the duration between the two points
    auto elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start);
    
    // returns the raw number of ticks (nanoseconds)
    return (uint64_t)elapsed.count();
}

#include <stdio.h>

#define ARRAY_SIZE 256
#define ARRAY_SIZE_IN_BYTES (sizeof(unsigned int) * (ARRAY_SIZE))

/* Declare  statically two arrays of ARRAY_SIZE each */
unsigned int cpu_block[ARRAY_SIZE];
unsigned int cpu_thread[ARRAY_SIZE];


__global__
void what_is_my_id(unsigned int * block, unsigned int * thread)
{
	const unsigned int thread_idx = (blockIdx.x * blockDim.x) + threadIdx.x;
	block[thread_idx] = blockIdx.x;
	thread[thread_idx] = threadIdx.x;
}

void main_sub0()
{
	uint64_t average = 0;
	for (int i=0;i<10000;i++){
	auto start = std::chrono::steady_clock::now();
	/* Declare pointers for GPU based params */
	unsigned int *gpu_block;
	unsigned int *gpu_thread;

	cudaMalloc((void **)&gpu_block, ARRAY_SIZE_IN_BYTES);
	cudaMalloc((void **)&gpu_thread, ARRAY_SIZE_IN_BYTES);
	cudaMemcpy( cpu_block, gpu_block, ARRAY_SIZE_IN_BYTES, cudaMemcpyHostToDevice );
	cudaMemcpy( cpu_thread, gpu_thread, ARRAY_SIZE_IN_BYTES, cudaMemcpyHostToDevice );

	const unsigned int num_blocks = ARRAY_SIZE/32;
	const unsigned int num_threads = ARRAY_SIZE/num_blocks;

	/* Execute our kernel */
	what_is_my_id<<<num_blocks, num_threads>>>(gpu_block, gpu_thread);

	/* Free the arrays on the GPU as now we're done with them */
	cudaMemcpy( cpu_block, gpu_block, ARRAY_SIZE_IN_BYTES, cudaMemcpyDeviceToHost );
	cudaMemcpy( cpu_thread, gpu_thread, ARRAY_SIZE_IN_BYTES, cudaMemcpyDeviceToHost );
	cudaFree(gpu_block);
	cudaFree(gpu_thread);
	average = average+get_nanos(start);
	}
	printf("used time: %" PRIu64 "\n",average);
	/* Iterate through the arrays and print */
	/*
	for(unsigned int i = 0; i < ARRAY_SIZE; i++)
	{
		printf("Thread: %2u - Block: %2u\n",cpu_thread[i],cpu_block[i]);
	}
	*/
}

int main()
{
	main_sub0();

	return EXIT_SUCCESS;
}
