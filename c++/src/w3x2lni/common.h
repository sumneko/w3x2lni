#pragma once

#define _CRT_SECURE_NO_WARNINGS
#include <Windows.h>
#include <stdio.h>

struct strview {
	const wchar_t* buf;
	size_t len;
	strview(const wchar_t* str);
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
	path();
	template <class T, size_t n>
	path& operator /(T(&str)[n]) {
		*this += L"\\";
		*this += str;
		return *this;
	}
};

struct pipe {
	~pipe();
	bool open(int type);
	size_t read(char* buf, size_t len);

	HANDLE f = NULL;
	HANDLE h = NULL;
	FILE* file = NULL;
};

bool execute_lua(pipe* out, pipe* err);
