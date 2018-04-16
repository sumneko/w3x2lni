#include "common.h"
extern "C" {
#include "../utf8/unicode.h"
}

void Error() 
{
	wchar_t* msg = 0;
	DWORD ok = ::FormatMessageW(
		FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_IGNORE_INSERTS,
		NULL,
		::GetLastError(),
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
		reinterpret_cast<LPWSTR>(&msg),
		0,
		NULL);
	if (ok && msg)
	{
		MessageBoxW(0, msg, L"Error!", 0);
	}
}

int __stdcall wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow)
{
	pipe err;
	if (!err.open('r')) {
		return -1;
	}

	if (!execute_lua(nullptr, &err)) {
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
		MessageBoxW(0, u2w(msg), L"Error!", 0);
	}
	return 0;
}
