#include "common.h"

int __stdcall wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow)
{
	pipe err;
	if (!err.open('r')) {
		return EXIT_FAILURE;
	}

	if (!execute_lua(L"GUI", nullptr, &err)) {
		return EXIT_FAILURE;
	}

	char msg[2048];
	size_t pos = 0;
	for (;;) {
		size_t len = err.read(msg + pos, sizeof msg - pos - 1);
		if (len == -1) {
			break;
		}
		if (len == 0) {
			Sleep(200);
			continue;
		}
		pos += len;
	}
	if (pos) {
		msg[pos] = 0;
		execute_crashreport(L"GUI", msg, false);
		return EXIT_FAILURE;
	}
	return EXIT_SUCCESS;
}
