# OpenVM Sail RISC-V Lean Model

This repository publishes the Lean model generated from the OpenVM adaptation of
Sail RISC-V. It is used to verify execution equivalence between OpenVM and Sail.

## Repository contents

- `Lean_RV32D/` contains the generated Lake package.
- `Lean_RV32D/lean-sail/` contains its vendored `Sail` runtime dependency.
- `SAIL_SRC_COMMIT` pins the exact `sail-riscv` source revision.
- `Lean_RV32D/sail-source-provenance.tsv` records the source, compiler, and
  toolchain inputs used for generation.
- `generate-provider.sh` reproduces the package from the pinned source.

## Reproducibility

The model and its vendored `Sail` runtime use Lean 4.34.0. The model is
generated with Sail 0.20.2. Every provider update is independently regenerated
and compared in CI, and the runtime and model are compiled in a separate build job.

To reproduce the package locally, install OCaml 5.2.1, Sail 0.20.2, and Z3,
then run:

```bash
./generate-provider.sh /tmp/sail-provider /tmp/sail-provider-z3/memo.db
diff --recursive --brief /tmp/sail-provider/Lean_RV32D Lean_RV32D
```

To compile the runtime and generated model, install
[elan](https://github.com/leanprover/elan) and run:

```bash
cd Lean_RV32D
lake build Sail LeanRV32D
```

Lake selects Lean 4.34.0 from the package's `lean-toolchain` file.
