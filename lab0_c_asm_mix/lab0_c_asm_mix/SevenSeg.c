#define min(x,y) ((x) < (y) ? (x) : (y));
#include <stdio.h>
#include <stdbool.h>

void compare()
{
	unsigned int* hex = (unsigned int*) 0xffff200c;
	unsigned int* led = (unsigned int*) 0xffff2008;

	hex[0] = 0x58;
	hex[1] = 0x10;
	hex[2] = 0x40;
	hex[3] = 0x79;

	*led = 0x1e0;
}
