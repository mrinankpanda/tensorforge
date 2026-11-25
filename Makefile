IVERILOG ?= iverilog
VVP ?= vvp

.PHONY: test-pe
test-pe:
	@set -eu; \
	build_dir=$$(mktemp -d); \
	trap 'rm -rf "$$build_dir"' EXIT; \
	"$(IVERILOG)" -g2012 -Wall -s tb_tf_pe -o "$$build_dir/tb_tf_pe.vvp" \
		rtl/tf_pe.sv verification/unit/tb_tf_pe.sv; \
	"$(VVP)" "$$build_dir/tb_tf_pe.vvp"
