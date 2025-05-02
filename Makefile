run:
	zig build run
test:
	zig build -DbuildOnly=true test --summary new
build-linux:
	zig build -DbuildOnly=true -Doptimize=ReleaseSmall --prefix-exe-dir linux
build-windows:
	zig build -DbuildOnly=true -Dtarget=x86_64-windows -Doptimize=ReleaseSmall --prefix-exe-dir windows
build-web:
	zig build -DbuildOnly=true -Dtarget=wasm32-emscripten -Doptimize=ReleaseSmall --sysroot ${EMSDK}/upstream/emscripten