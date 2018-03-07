#define _CRT_SECURE_NO_WARNINGS
#include <Windows.h>
#include <shlwapi.h>
#pragma comment(lib, "shlwapi.lib")

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
		len = wcslen(buf);
	}
	template <class T, size_t n>
	path& operator /(T(&str)[n]) {
		*this += L"/";
		*this += str;
		return *this;
	}
};

int __stdcall WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	STARTUPINFOW            si = { sizeof STARTUPINFOW };
	PROCESS_INFORMATION     pi = { 0 };
	DWORD flags = NORMAL_PRIORITY_CLASS;
	if (!(__argc >= 2 && strcmp(__argv[1], "-console") == 0)) {
		flags |= CREATE_NO_WINDOW;
	}

	path app = path() / L"bin" / L"w3x2lni.exe";
	path cwd = path() / L"script";
	strbuilder<32768> cmd;
	cmd += L"\"";
	cmd += app;
	cmd += L"\" -E \"";
	cmd += path() / L"script" / L"main.lua";
	cmd += L"\"";

	if (!::CreateProcessW(
		app.string(),
		cmd.string(),
		NULL, NULL, FALSE, flags, NULL,
		cwd.string(),
		&si, &pi))
	{
		return -1;
	}

	::CloseHandle(pi.hThread);
	::CloseHandle(pi.hProcess);
	return 0;
}
