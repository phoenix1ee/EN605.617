#include <stdio.h>
#include <stdlib.h>

// Create and return a pointer to an array of size rows and cols
// populate with random value
int* create_2d_array(int rows, int cols) {
    int* array = (int*)malloc(rows * cols * sizeof(int));
srand(time(NULL));
    for (int i = 0; i < rows * cols; i++) {
		
		// Initialize with random number between 1-999
        array[i] = rand() % 999+1;
    }
    return array;
}

//kernel function
__global__ void normalize(int *a, int min) 
{
	//total blocks
	int totalblock = blockIdx.z*gridDim.x*gridDim.y;
	int blocksize = blockDim.x*blockDim.y*blockDim.z;
	int globalthread_id = totalblock*blocksize + blockDim.x*blockDim.y*threadIdx.z + blockDim.x*threadIdx.y + threadIdx.x;
	//normalization by an amount "min" if the element is >min
	if (a[globalthread_id] > min) {
        a[globalthread_id] = a[globalthread_id]-min;
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
	int width = 32;
	int height = blockSize/width;

	// an arbitrary value
	int normalizamount = 1;

	// create 2d-array
	int* matrix=create_2d_array(height*numBlocks,width);
	int* d_matrix;

	for (int i = 0; i < height*numBlocks; i++) {
        for (int j = 0; j < width; j++) {
            // Indexing formula: row * width + column
            printf("%4d ", matrix[i * width + j]);
        }
        printf("\n"); // New line after each row
    }

	printf("\n");

	//allocate memory and copy to device
	cudaMalloc((void **)&d_matrix, totalThreads*sizeof(int));
	cudaMemcpy( d_matrix, matrix, totalThreads*sizeof(int), cudaMemcpyHostToDevice );

	//define grid and block size
	dim3 dimBlock( 32, height, 1 );
	dim3 dimGrid(numBlocks, 1, 1 );

	/* Execute our kernel */
	normalize<<<dimGrid, dimBlock>>>(d_matrix, normalizamount);
	cudaDeviceSynchronize();
	/* Free the arrays on the GPU as now we're done with them */
	cudaMemcpy( matrix, d_matrix, totalThreads*sizeof(int), cudaMemcpyDeviceToHost );
	cudaFree(d_matrix);

	for (int i = 0; i < height*numBlocks; i++) {
        for (int j = 0; j < width; j++) {
            // Indexing formula: row * width + column
            printf("%4d ", matrix[i * width + j]);
        }
        printf("\n"); // New line after each row
    }
}
