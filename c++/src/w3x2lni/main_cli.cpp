#include "common.h"
#include <stdio.h>

int __cdecl wmain()
{
	pipe out;
	if (!out.open('r')) {
		return -1;
	}

	if (!execute_lua(&out, nullptr)) {
		return -1;
	}

	char msg[2048];
	for (;;) {
		size_t len = out.read(msg, sizeof msg);
		if (len == -1) {
			break;
		}
		if (len == 0) {
			Sleep(200);
			continue;
		}
		fwrite(msg, len, 1, stdout);
	}
	return 0;
}
