#define min(x,y) ((x) < (y) ? (x) : (y));
#include <stdio.h>
#include <stdbool.h>

void compare(int arr[])
{
	
	int i, j, tmp;
	/*
	int arr[32] =
			{ 2, 0, -7, -1, 3, 8, -4, 10
			, -9, -16, 15, 13, 1, 4, -3, 14
			, -8, -10, -15, 6, -13, -5, 9, 12
			, -11, -14, -6, 11, 5, 7, -2, -12
			};
	*/
	
	for(int i = 0; i < 31; i++)
	{
		for(int j = 0; j< 31-i; j++)
		{
			tmp = arr[j];
			arr[j] = arr[j+1];
			arr[j+1] = tmp;	
		}
	};
	
}
