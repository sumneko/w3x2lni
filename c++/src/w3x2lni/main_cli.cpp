#include "common.h"
#include <stdio.h>
#include <string>
#include "../lua/lua.hpp"
extern "C" {
#include "../utf8/unicode.h"
}

struct luaparse {
	luaparse()
		: L(luaL_newstate()) {
	}
	~luaparse() {
		if (L) lua_close(L);
	}
	bool loadstring(const std::string& str) {
		if (luaL_loadstring(L, str.c_str()) || lua_pcall(L, 0, 1, 0)) {
			lua_pop(L, 1);
			return false;
		}
		return true;
	}
	operator lua_State*() {
		return L;
	}
	lua_State* L;
};


struct protocol {
	int stat = 0;
	size_t need = 0;
	std::string buf;
	luaparse L;

	bool unpack(const char* str, size_t len) {
		for (size_t i = 0; i < len; ++i)
		{
			char c = str[i];
			buf.push_back(c);
			switch (stat)
			{
			case 0:
				if (c == '\r') stat = 1;
				break;
			case 1:
				stat = 0;
				if (c == '\n') {
					if (buf.substr(0, 16) != "Content-Length: ") {
						return false;
					}
					try {
						need = (size_t)std::stol(buf.substr(16, buf.size() - 18));
						stat = 2;
					}
					catch (...) {
						return false;
					}
					buf.clear();
				}
				break;
			case 2:
				if (buf.size() >= need)
				{
					if (!messsage(buf.substr(0, need))) {
						return false;
					}
					buf.clear();
					stat = 0;
				}
				break;
			}
		}
		return true;
	}

	bool messsage(const std::string& str) {
		if (!L.loadstring("return " + str)) {
			return false;
		}
		lua_getfield(L, -1, "args"); 
		size_t len = 0;
		const char* msg = lua_tolstring(L, -1, &len); 
		const wchar_t* wmsg = u2w(msg);
		DWORD wlen = 0;
		WriteConsoleW(GetStdHandle(STD_OUTPUT_HANDLE), wmsg, wcslen(wmsg), &wlen, 0);
		WriteConsoleW(GetStdHandle(STD_OUTPUT_HANDLE), L"\r\n", 2, &wlen, 0);
		lua_pop(L, 2);
		return true;
	}
};

int __cdecl wmain()
{
	pipe out;
	if (!out.open('r')) {
		return -1;
	}

	if (!execute_lua(&out, nullptr)) {
		return -1;
	}

	protocol proto;
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
		proto.unpack(msg, len);
	}
	return 0;
}
