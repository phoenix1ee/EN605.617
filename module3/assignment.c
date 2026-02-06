#include <stdio.h>
#include <stdlib.h>
#include <time.h>

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
void normalize(int *a, int rows, int cols, int min) 
{
	//normalization by an amount "min" if the element is >min
	for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            // Indexing formula: row * width + column
            a[i * cols + j]-=1;
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
	int width = 32;
	int height = blockSize/width;

	// an arbitrary value
	int normalizamount = 1;

	// create 2d-array
	int* matrix=create_2d_array(height*numBlocks,width);

	for (int i = 0; i < height*numBlocks; i++) {
        for (int j = 0; j < width; j++) {
            // Indexing formula: row * width + column
            printf("%4d ", matrix[i * width + j]);
        }
        printf("\n"); // New line after each row
    }

	printf("\n");

	/* Execute function */
	normalize(matrix, height*numBlocks,width,normalizamount);

	for (int i = 0; i < height*numBlocks; i++) {
        for (int j = 0; j < width; j++) {
            // Indexing formula: row * width + column
            printf("%4d ", matrix[i * width + j]);
        }
        printf("\n"); // New line after each row
    }
}
