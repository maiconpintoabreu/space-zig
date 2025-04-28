build:
	make build-linux
	make build-web

run:
	zig build run
build-linux:
	zig build
build-web:
	zig build -Dtarget=wasm32-emscripten --sysroot ../emsdk/upstream/emscripten