# tensorforge
Parameterized SystemVerilog tensor accelerator featuring a systolic array, tiled matrix multiplication, and hardware performance analysis.

## Processing element

`tf_pe` multiplies a pair of signed inputs and adds the product to a 32-bit running sum when both inputs are valid. INT8 mode uses the whole input byte. INT4 mode uses its low four bits. On each rising clock edge, the cell forwards the input bytes and their valid bits to neighboring cells. `hold` freezes forwarding and accumulation. `clear` zeros the sum even during a hold. The synchronous active-low `rst_n` resets the sum and forwarding registers.

## Run the processing element tests

With Icarus Verilog (`iverilog` and `vvp`) installed, run from the repository root.

```sh
make test-pe
```
