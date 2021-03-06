NPROCS := 1
OS := $(shell uname)
export NPROCS

ifeq ($J,)

ifeq ($(OS),Linux)
  NPROCS := $(shell grep -c ^processor /proc/cpuinfo)
else ifeq ($(OS),Darwin)
  NPROCS := $(shell system_profiler | awk '/Number of CPUs/ {print $$4}{next;}')
endif # $(OS)

else
  NPROCS := $J
endif # $J

gentoo:
	[[ -d files ]] || mkdir  files
	scripts/download.sh
	packer build -var 'procs=$(NPROCS)' gentoo.json
gentoo-qemu:
	[[ -d files ]] || mkdir  files
	scripts/download.sh
	packer build -only=qemu -var 'procs=$(NPROCS)' gentoo.json
