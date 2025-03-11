#!/usr/bin/env python3

def lfsr_32(state):
    """
    Advance the 32-bit LFSR one step and return the new state.
    Taps are at bit positions: 32, 22, 2, 1 (1-indexed).
    """
    # Extract the tap bits. (bit 0 is the LSB)
    bit0 = (state >> 0) & 1  # Tap at bit 1 (LSB)
    bit1 = (state >> 1) & 1  # Tap at bit 2
    bit21 = (state >> 21) & 1  # Tap at bit 22
    bit31 = (state >> 31) & 1  # Tap at bit 32 (MSB)

    # XOR of the tap bits becomes the new MSB after the shift
    feedback = bit31 ^ bit21 ^ bit0 ^ bit1 

    # Shift left by 1 and insert feedback at the LSB
    state = ((state << 1) | feedback) & 0xFFFFFFFF

    return state


def main():
    # Starting seed
    state = 0xACE1ACE1

    # Generate and print the next 10 values of the LFSR
    for i in range(1, 11):
        state = lfsr_32(state)
        print(f"Value {i}: 0x{state:08X}")

if __name__ == "__main__":
    main()
