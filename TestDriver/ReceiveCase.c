/*
 * ReceiveCase.c
 *
 * Created: 8/3/2020 3:31:36 PM
 *  Author: Tim
 */ 


#include "stdio.h"
#include <math.h>

#undef getchar	// let's use function version


typedef union
{
	uint64_t	u64;
	float		f;
	double		d;
} AllTypes;

void ReceiveCase()
{
	int			typ;
	int			cArgs;
	int			op;
	AllTypes	arg1;
	AllTypes	arg2;

	typ = getchar();
	cArgs = getchar();

	scanf(" %llx ", &arg1.u64);
	if (cArgs == '2')
		scanf("%llx ", &arg2.u64);

	op = getchar();

	switch (op)
	{
		case '/':	// divide
			switch (typ)
			{
				case 'f':
					arg1.f /= arg2.f;
					break;

				case 'd':
					arg1.d /= arg2.d;
					break;
			}
			break;

		case '#':	// square root
			switch (typ)
			{
				case 'f':
					arg1.f = sqrtf(arg1.f);
					break;

				case 'd':
					arg1.d = sqrt(arg1.d);
					break;
			}
			break;
	}

	// Send back results
	printf("@%llx\n", arg1.u64);
}
