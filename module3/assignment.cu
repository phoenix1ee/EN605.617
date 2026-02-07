#include <stdio.h>
#include <stdlib.h>
#include <climits>
#include <time.h>

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
	for (int row = blockoffset; row < height; row += gridsize) {
		//use each block as for a row
		int rowStart = row * width;
		//find minimum
		int localMin = INT_MAX;
		int tid = threadIdx.x;
		// assume blockDim.x=32
		// 1. Grid-Stride Loop: Handle rows wider than 32 elements
		// loop thru entire row to finds the 32 min for each row
		for (int x = tid; x < width; x += 32) {
			localMin = min(localMin, a[rowStart+x]);
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

	printf("matrix size= row %d * col %d\n",(bheight*numBlocks),bwidth);

	//allocate memory and copy to device
	cudaMalloc((void **)&d_matrix, totalThreads*sizeof(int));
	cudaMemcpy( d_matrix, matrix, totalThreads*sizeof(int), cudaMemcpyHostToDevice );

	//define grid and block size
	dim3 dimBlock( bwidth, bheight, 1 );
	dim3 dimGrid(numBlocks, 1, 1 );

	/* Execute our kernel */
	rowreduction<<<dimGrid, dimBlock>>>(d_matrix, bwidth, bheight*2);
	cudaDeviceSynchronize();
	/* Free the arrays on the GPU as now we're done with them */
	cudaMemcpy( matrix, d_matrix, totalThreads*sizeof(int), cudaMemcpyDeviceToHost );
	cudaFree(d_matrix);
	//print points (i,j)<(10,32)
	/*for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 32; j++) {
            printf("%2d ", matrix[i * bwidth + j]);
        }
        printf("\n"); // New line after each row
    }*/
}
