# Assembly → C Modernization Notes

## Source System
- **Name**: Apollo 11 AGC (Apollo Guidance Computer) - Luminary099 / Comanche055
- **Language**: AGC Assembly (custom instruction set)
- **Source**: chrislgarry/Apollo-11
- **LOC**: ~150K+ lines of AGC assembly

## AGC Architecture Overview

The Apollo Guidance Computer was a 15-bit word, fixed-point machine:
- **Word size**: 15 bits + 1 sign bit (ones' complement)
- **Memory**: 2K erasable (RAM), 36K fixed (ROM)
- **Clock**: 1.024 MHz
- **Registers**: A (accumulator), L (lower), Q (return addr), Z (PC), BB (bank)
- **Arithmetic**: Ones' complement, fixed-point fractional

## AGC Instruction Set Mapping

| AGC Instruction | C Equivalent | Notes |
|----------------|-------------|-------|
| AD | `agc_add()` | Ones' complement add with end-around carry |
| SU | `agc_subtract()` | Implemented via complement and add |
| MP | `agc_multiply()` | Result in A,L register pair (DP) |
| DV | `agc_divide()` | Requires dividend < divisor |
| CA | `x = memory[addr]` | Copy to accumulator |
| CS | `x = ~memory[addr]` | Copy complement to accumulator |
| TS | `memory[addr] = a` | Transfer to storage |
| XCH | `temp = a; a = memory[addr]; memory[addr] = temp` | Exchange |
| TC | `function_call()` | Transfer control (subroutine call) |
| TCF | `goto label` | Transfer control, no return |
| CCS | `if/else` | Count, Compare, Skip (4-way branch) |
| INDEX | Computed address | Address modification before next instruction |
| INHINT | Disable interrupts | `interrupts_enabled = false` |
| RELINT | Enable interrupts | `interrupts_enabled = true` |
| EXTEND | Instruction prefix | Selects extended instruction set |

## Register Handling

| AGC Register | C Mapping | Purpose |
|-------------|-----------|---------|
| A (Accumulator) | Local variables | Primary computation register |
| L (Lower) | Second return value / temp | Lower word of double precision |
| Q (Return) | Stack frame / return address | Saved by TC instruction |
| Z (Program Counter) | Implicit (control flow) | Not directly mapped |
| BB (Bank) | Not needed | Memory banking eliminated |

## Fixed-Point Arithmetic Details

### Single Precision
- Format: 1 sign + 14 magnitude bits
- Range: [-1.0, +1.0) with resolution of 2^-14 (~0.00006)
- Ones' complement: negation = bitwise complement

### Double Precision
- Format: 2 consecutive words = 28 effective bits
- Range: [-1.0, +1.0) with resolution of 2^-28 (~3.7e-9)
- High word contains sign, low word sign bit is always 0

### Key Differences from Two's Complement
1. **Two zeros**: Positive zero (0x0000) and negative zero (0x7FFF)
2. **Symmetric range**: Both +max and -max are representable
3. **End-around carry**: Carry out of MSB is added back to LSB

## What Was Simplified

1. **Memory banking**: AGC had complex bank-switched memory. C uses flat address space.
2. **Waitlist/timer system**: AGC had a cooperative multitasking system driven by timer interrupts. Replaced with sequential function calls.
3. **Restart protection**: AGC had elaborate restart groups to recover from hardware restarts mid-computation. Not needed in modern systems.
4. **I/O channels**: AGC communicated with spacecraft hardware through I/O channels. Replaced with function parameters.
5. **Interpretive language**: AGC had a software-implemented "interpreter" for complex math operations (trig, vector, matrix). Replaced with C math library.
6. **Bit-level packing**: AGC packed multiple values into single words to save memory. C uses separate variables.

## Modernized Routines

### Guidance (guidance.c)
- Lambert targeting algorithm for orbit transfer calculation
- Vector operations (cross product, dot product, normalize)
- Replaces AGC interpretive language routines: LAMBERT, MIDGIM, CALCRVG

### Navigation (navigation.c)
- Kepler orbit propagation using universal variables
- IMU (PIPA) integration for state vector updates
- Coordinate transformations (ECI↔ECEF)
- Replaces AGC routines: KEPLER, PIPA, NAVIGATION

### Fixed-Point Arithmetic (fixed_point.c)
- Ones' complement fixed-point arithmetic library
- Add, subtract, multiply, divide matching AGC behavior
- Double precision operations
- Angle conversion utilities

## Building and Testing

```bash
cd modernization-targets/assembly-to-c
make test
```

## Accuracy Considerations

- Fixed-point conversion round-trips accurate to ±1 LSB (2^-14 for SP)
- Orbital mechanics calculations use IEEE 754 double precision
- Kepler propagation preserves orbital radius to < 1 ppm for circular orbits
- Vector operations exact to machine epsilon (~1e-15)
