build:
	make build-web
	make build-linux
	make build-windows

run:
	zig build run
build-linux:
	zig build -Doptimize=ReleaseSmall --prefix-exe-dir linux
build-windows:
	zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSmall --prefix-exe-dir windows
build-web:
	zig build -Dtarget=wasm32-emscripten -Doptimize=ReleaseSmall --prefix-exe-dir web --sysroot ../emsdk/upstream/emscripten