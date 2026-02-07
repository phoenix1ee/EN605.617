#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <climits>

// Create and return a pointer to an array of size rows and cols
// populate with random value
int* create_2d_array(int rows, int cols) {
    int* m = (int*)malloc(rows * cols * sizeof(int));
	srand(time(NULL));
    for (int i = 0; i < rows * cols; i++) {
		// Initialize with random number between 1-999
        m[i] = rand() % 999+1;
    }
    return m;
}

//kernel function
void rowreduction(int *a, int rows, int cols) 
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
	printf("matrix size= row %d * col %d\n",(bheight*numBlocks),bwidth);
	
	//print points (i,j)<(10,32)
	/*for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 32; j++) {
            printf("%2d,", matrix[i * bwidth + j]);
        }
        printf("\n"); // New line after each row
    }*/

	printf("\n");
	
	/* Execute function */
	rowreduction(matrix, bheight*numBlocks,bwidth);

}
