ifeq ($(OS),Windows_NT)
    default: windows
else
    default: linux
endif

linux:
	nvcc assignment.cu -o assignment -lrt

windows:
	nvcc assignment.cu -o assignment.exe