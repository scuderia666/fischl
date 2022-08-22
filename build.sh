#!/bin/sh

err() { echo $@; exit 1; }

if [[ ! -f xvo ]] || [[ -n $@ ]]; then
	if ! command -v v &> /dev/null; then
		err "please install v"
	fi

	mkdir -p out
	v xvo-src/ -o out/xvo
fi

if [[ ! -f out/xvo ]]; then
	err "couldnt build xvo"
fi

build_toolchain() {
	build() {
		./out/xvo build $@ \
			-root %pwd/out/tools \
			-pkg %pwd/toolchain/pkg \
			-stuff %pwd/toolchain/stuff \
			-dl %pwd/out/tc_dl \
			-bl %pwd/out/tc_build \
			-scripts %pwd/scripts \
			-target %arch-linux-musl \
			-debug yes
	}

	build musl
}

emerge() {
	./out/xvo emerge $@ \
		-root %pwd/out/rootfs \
		-tools %pwd/out/tools \
		-pkg %pwd/pkg \
		-stuff %pwd/stuff \
		-dl %pwd/out/dl \
		-bl %pwd/out/build \
		-scripts %pwd/scripts \
		-target %arch-linux-musl \
		-debug yes
}

main() {
	case $1 in
		toolchain) build_toolchain ;;
		*) emerge $@ ;;
	esac

	shift $((OPTIND -1))
}

main $@
