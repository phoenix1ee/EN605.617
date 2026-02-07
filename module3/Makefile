ifeq ($(OS),Windows_NT)
    default: windows
else
    default: linux
endif

linux:
	# use -ccbin /usr/bin/gcc-11 for myself
	nvcc assignment.cu -o assignment.exe -lrt

windows:
	nvcc assignment.cu -o assignment.exe