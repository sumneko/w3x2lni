#include "common.h"
extern "C" {
#include "../utf8/unicode.h"
}

int __stdcall wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow)
{
	pipe err;
	if (!err.open('r')) {
		return -1;
	}

	if (!execute_lua(L"GUI", nullptr, &err)) {
		return -1;
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
		execute_crashreport(L"GUI", msg);
	}
	return 0;
}
