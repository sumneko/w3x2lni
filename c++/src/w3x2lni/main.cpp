#define _CRT_SECURE_NO_WARNINGS
#include <Windows.h>
#include <shlwapi.h>
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

int __stdcall wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow)
{
	STARTUPINFOW            si = { sizeof STARTUPINFOW };
	PROCESS_INFORMATION     pi = { 0 };
	DWORD flags = NORMAL_PRIORITY_CLASS | CREATE_UNICODE_ENVIRONMENT | CREATE_NO_WINDOW;

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

	if (!::CreateProcessW(
		app.string(),
		cmd.string(),
		NULL, NULL, FALSE, flags,
		env.string(),
		cwd.string(),
		&si, &pi))
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
		return -1;
	}

	::CloseHandle(pi.hThread);
	::CloseHandle(pi.hProcess);
	return 0;
}
