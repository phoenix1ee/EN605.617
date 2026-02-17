ifeq ($(OS),Windows_NT)
    default: windows
else
    default: linux
endif

linux:
	# use -ccbin /usr/bin/gcc-11 for myself
	nvcc global_memory.cu -o global_memory.exe -lrt
	nvcc host_memory.cu -o host_memory.exe -lrt
windows:
	nvcc global_memory.cu -o global_memory.exe
	nvcc host_memory.cu -o host_memory.exe

