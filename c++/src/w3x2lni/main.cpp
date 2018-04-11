#define _CRT_SECURE_NO_WARNINGS
#include <Windows.h>
#include <shlwapi.h>
#include <algorithm>
#include <utility>
extern "C" {
#include "../utf8/unicode.h"
}
#pragma comment(lib, "shlwapi.lib")

struct strview {
	const wchar_t* buf;
	size_t len;
	strview(const wchar_t* str)
		: buf(str)
		, len(wcslen(str))
	{ }
};

template <size_t N>
struct strbuilder {
	wchar_t buf[N];
	size_t  len = 0;
	void append(const wchar_t* str, size_t n) {
		if (len + n >= sizeof buf / sizeof buf[0]) {
			return;
		}
		wcsncpy(buf + len, str, n);
		len += n;
	}
	template <class T, size_t n>
	void operator +=(T(&str)[n]) {
		append(str, n - 1);
	}
	template <size_t n>
	void operator +=(const strbuilder<n>& str) {
		append(str.buf, str.len);
	}
	void operator +=(const strview& str) {
		append(str.buf, str.len);
	}
	wchar_t* string() {
		buf[len] = L'\0';
		return buf;
	}
};

struct path : public strbuilder<MAX_PATH> {
	path() {
		::GetModuleFileNameW(NULL, buf, sizeof buf / sizeof buf[0]);
		::PathRemoveBlanksW(buf);
		::PathUnquoteSpacesW(buf);
		::PathRemoveBackslashW(buf);
		::PathRemoveFileSpecW(buf);
#if _DEBUG
		::PathRemoveFileSpecW(buf);
		::PathRemoveFileSpecW(buf);
		::PathRemoveFileSpecW(buf);
		::PathRemoveFileSpecW(buf);
		::PathRemoveFileSpecW(buf);
#endif
		len = wcslen(buf);
	}
	template <class T, size_t n>
	path& operator /(T(&str)[n]) {
		*this += L"\\";
		*this += str;
		return *this;
	}
};

static std::pair<HANDLE, HANDLE> pipe_open(int type)
{
	SECURITY_ATTRIBUTES sa;
	sa.nLength = sizeof(SECURITY_ATTRIBUTES);
	sa.bInheritHandle = FALSE;
	sa.lpSecurityDescriptor = NULL;
	HANDLE rd = NULL, wr = NULL;
	if (!::CreatePipe(&rd, &wr, &sa, 0)) {
		return std::make_pair((HANDLE)NULL, (HANDLE)NULL);
	}
	HANDLE f = type == 'r' ? rd : wr;
	HANDLE h = type == 'r' ? wr : rd;
	return std::make_pair(f, h);
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
	path app = path() / L"bin" / L"w2l-worker.exe";
	path cwd = path() / L"script";
	strbuilder<32768> cmd;
	cmd += L"\"";
	cmd += app;
	cmd += L"\" -E \"";
	cmd += path() / L"script" / L"main.lua";
	cmd += L"\"";

	for (int i = 1; i < __argc; ++i) {
		cmd += L" \"";
		cmd += __wargv[i];
		cmd += L"\"";
	}

	strbuilder<1024> env;
	env += L"PATH=";
	env += path() / L"bin";
	env += L"\0";

	auto [err_f, err_h] = pipe_open('r');
	if (!err_f || !err_h) {
		Error();
		return -1;
	}
	::SetHandleInformation(err_h, HANDLE_FLAG_INHERIT, HANDLE_FLAG_INHERIT);

	STARTUPINFOW            si = { sizeof STARTUPINFOW };
	PROCESS_INFORMATION     pi = { 0 };
	si.dwFlags = STARTF_USESTDHANDLES;
	si.hStdInput = INVALID_HANDLE_VALUE;
	si.hStdOutput = INVALID_HANDLE_VALUE;
	si.hStdError = err_h;

	if (!::CreateProcessW(
		app.string(),
		cmd.string(),
		NULL, NULL, TRUE, 
		NORMAL_PRIORITY_CLASS | CREATE_UNICODE_ENVIRONMENT | CREATE_NO_WINDOW,
		env.string(),
		cwd.string(),
		&si, &pi)) 
	{
		::CloseHandle(err_f);
		::CloseHandle(err_h);
		Error();
		return -1;
	}

	::CloseHandle(err_h);
	::CloseHandle(pi.hThread);
	::CloseHandle(pi.hProcess);

	char msg[2048];
	size_t pos = 0;
	for (;;) {
		DWORD rlen = 0;
		if (!PeekNamedPipe(err_f, 0, 0, 0, &rlen, 0)) {
			break;
		}
		if (rlen == 0) {
			Sleep(200);
			continue;
		}
		DWORD len = (std::min)(rlen, (DWORD)(sizeof msg - pos - 1));
		if (rlen == 0) {
			break;
		}
		if (!ReadFile(err_f, msg + pos, len, &rlen, 0)) {
			break;
		}
		pos += rlen;
	}
	if (pos) {
		msg[pos] = 0;
		MessageBoxW(0, u2w(msg), L"Error!", 0);
	}
	::CloseHandle(err_f);
	return 0;
}
