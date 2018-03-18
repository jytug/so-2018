#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

int set_bit(uint64_t *x, unsigned char bit) {
    int which = bit / 64;
    uint64_t shift = ((uint64_t)1) << (63 - bit % 64);
    if (x[which] & shift)
        return 1;
    x[which] |= shift;
    return 0;
}
