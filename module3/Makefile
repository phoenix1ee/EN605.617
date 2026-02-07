all: assignment.cpp assignment.cu
	gcc assignment.cpp -o assignment.exe
	nvcc -ccbin /usr/bin/gcc-11 assignment.cu -o assignmentcuda.exe