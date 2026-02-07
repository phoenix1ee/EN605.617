#include <stdio.h>
#include <stdlib.h>
#include <climits>
#include <time.h>
#include <stdint.h>
// For PRIu64
#include <cinttypes>
//multi platform time function

#if defined(_WIN32)

#include <windows.h>

// Windows replacement for struct timespec using QPC
static inline void get_monotonic_timespec(struct timespec *ts) {
    static LARGE_INTEGER freq;
    static int initialized = 0;

    if (!initialized) {
        QueryPerformanceFrequency(&freq);
        initialized = 1;
    }

    LARGE_INTEGER counter;
    QueryPerformanceCounter(&counter);

    // Convert QPC ticks → nanoseconds
    uint64_t ns = (uint64_t)(counter.QuadPart * 1000000000ull / freq.QuadPart);

    ts->tv_sec  = ns / 1000000000ull;
    ts->tv_nsec = ns % 1000000000ull;
}

uint64_t get_nanos(struct timespec start) {
    struct timespec end;
    get_monotonic_timespec(&end);

    uint64_t diff =
        (uint64_t)(end.tv_sec - start.tv_sec) * 1000000000ull +
        (uint64_t)(end.tv_nsec - start.tv_nsec);

    return diff;
}

#else
//linux version
uint64_t get_nanos(struct timespec start) {
    struct timespec end;
	// Get current time from the monotonic clock
    clock_gettime(CLOCK_MONOTONIC, &end);
	// Calculate difference: (seconds * 1e9) + nanoseconds
    uint64_t diff =(uint64_t)(end.tv_sec - start.tv_sec) * 1000000000ull
					+(uint64_t)(end.tv_nsec - start.tv_nsec);
    return diff;
}

#endif

// Create and return a pointer to an array of size rows and cols
// populate with random value
int* create_2d_array(int rows, int cols) {
    int* m = (int*)malloc(rows * cols * sizeof(int));
	srand(time(NULL));
    for (int i = 0; i < (rows * cols); i++) {
		// Initialize with random number between 1-999
        m[i] = rand() % 999+1;		
    }
    return m;
}

//kernel function
__global__ void rowreduction(int *a, int width, int height) 
{
	int blockoffset = (blockIdx.z*gridDim.x*gridDim.y) + (gridDim.x*blockIdx.y) + blockIdx.x;
	int gridsize = gridDim.x*gridDim.y*gridDim.z;
	if (blockoffset >= height) return;
	for (int row = blockoffset; row < height; row += gridsize) {
		//use each block as for a row
		int rowStart = row * width;
		//find minimum
		int localMin = INT_MAX;
		int tid = threadIdx.x;
		// assume blockDim.x=32
		// loop thru entire row to finds the 32 min for each row
		for (int x = tid; x < width; x += 32) {
			if (a[rowStart+x]<localMin){
				localMin = a[rowStart+x];
			}
		}
		// find the real row minimum
		for (int offset = 16; offset > 0; offset /= 2) {
			localMin = min(localMin, __shfl_down_sync(0xffffffff, localMin, offset));
		}
		int rowMin = __shfl_sync(0xffffffff, localMin, 0);
		for (int x = tid; x < width; x += 32) {
			a[rowStart+x] -= rowMin;
		}
	}
}

//cpu function
void cpurowreduction(int *a, int rows, int cols) 
{
	//find minimum of a row and subtract every element of that row by the min found
	for (int i = 0; i < rows; i++) {
        int min = INT_MAX;
		// Indexing formula: row * width + column
		for (int j = 0; j < cols; j++) {
			if (a[i * cols + j]<min){
				min = a[i * cols + j];
			}
        }
		for (int j = 0; j < cols; j++) {
			a[i * cols + j]-=min;
        }
    }
}

int main(int argc, char** argv)
{
	// read command line arguments
	int totalThreads = (1 << 20);
	int blockSize = 256;
	
	if (argc >= 2) {
		totalThreads = atoi(argv[1]);
	}
	if (argc >= 3) {
		blockSize = atoi(argv[2]);
	}

	int numBlocks = totalThreads/blockSize;

	// validate command line arguments
	if (totalThreads % blockSize != 0) {
		++numBlocks;
		totalThreads = numBlocks*blockSize;
		
		printf("Warning: Total thread count is not evenly divisible by the block size\n");
		printf("The total number of threads will be rounded up to %d\n", totalThreads);
	}
	//block dimension
	int bwidth = 32;
	int bheight = blockSize/bwidth;

	// create an arbitrary 2d-array
	int* matrix=create_2d_array(bheight*numBlocks,bwidth);
	int* d_matrix;

	printf("GPU version:\nmatrix size= row %d * col %d\n",(bheight*numBlocks),bwidth);

	//GPU kernel
	struct timespec start;
	//call different version under different system
	#if defined(_WIN32)
    get_monotonic_timespec(&start);
	#else
    clock_gettime(CLOCK_MONOTONIC, &start);
	#endif
	//allocate memory and copy to device
	cudaMalloc((void **)&d_matrix, totalThreads*sizeof(int));
	cudaMemcpy( d_matrix, matrix, totalThreads*sizeof(int), cudaMemcpyHostToDevice );

	//define grid and block size
	dim3 dimBlock( bwidth, bheight, 1 );
	dim3 dimGrid(numBlocks, 1, 1 );

	/* Execute our kernel */
	rowreduction<<<dimGrid, dimBlock>>>(d_matrix, bwidth, bheight*numBlocks);
	cudaDeviceSynchronize();
	/* Free the arrays on the GPU as now we're done with them */
	cudaMemcpy( matrix, d_matrix, totalThreads*sizeof(int), cudaMemcpyDeviceToHost );
	cudaFree(d_matrix);

	uint64_t consumed = get_nanos(start);
	printf("GPU used time: %" PRIu64 "\n",consumed);
	printf("\n");

	//CPU function
	// create an arbitrary 2d-array
	matrix=create_2d_array(bheight*numBlocks,bwidth);
	printf("CPU version:\nmatrix size= row %d * col %d\n",(bheight*numBlocks),bwidth);

	//call different version under different system
	#if defined(_WIN32)
    get_monotonic_timespec(&start);
	#else
    clock_gettime(CLOCK_MONOTONIC, &start);
	#endif
	// Execute function
	cpurowreduction(matrix, bheight*numBlocks,bwidth);
	consumed = get_nanos(start);

	printf("CPU used time: %" PRIu64 "\n",consumed);
}
