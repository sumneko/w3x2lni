#include <Windows.h>
#include <WindowsX.h>
#include <Shobjidl.h>
#include <string.h>
#include <memory>
#include <string>
#include <lua.hpp>
#include "../unicode.h"

static int EXT = 0;
lua_State* gL = NULL;
HWND gW = NULL;

static std::wstring checkwstring(lua_State* L, int idx) {
	size_t len = 0;
	const char* str = luaL_checklstring(L, idx, &len);
	return u2w(std::string_view(str, len));
}

void OnDropFiles(HWND hwnd, HDROP hdrop)
{
	lua_State* L = gL;
	if (LUA_TTABLE != lua_rawgetp(L, LUA_REGISTRYINDEX, &EXT)) {
		lua_pop(L, 1);
		return;
	}
	if (LUA_TFUNCTION != lua_getfield(L, -1, "on_dropfile")) {
		lua_pop(L, 2);
		return;
	}

	UINT n = ::DragQueryFileW(hdrop, -1, NULL, 0);
	for (UINT i = 0; i < n; ++i)
	{
		UINT len = ::DragQueryFileW(hdrop, i, NULL, 0);
		len++;
		std::unique_ptr<wchar_t[]> buf(new wchar_t[len]);
		::DragQueryFileW(hdrop, i, buf.get(), len);
		std::string filename = w2u(std::wstring_view(buf.get(), (size_t)len));
		lua_pushlstring(L, filename.data(), filename.size() - 1);
	}
	if (lua_pcall(L, (int)n, 0, 0)) {
		printf("%s\n", lua_tostring(L, -1));
		lua_pop(L, 1);
	}
	::DragFinish(hdrop);

	lua_pop(L, 1);
}

void OnTimer(int delta)
{
	lua_State* L = gL;
	if (LUA_TTABLE != lua_rawgetp(L, LUA_REGISTRYINDEX, &EXT)) {
		lua_pop(L, 1);
		return;
	}
	if (LUA_TFUNCTION != lua_getfield(L, -1, "on_timer")) {
		lua_pop(L, 2);
		return;
	}
	lua_pushinteger(L, delta);
	if (lua_pcall(L, 1, 0, 0)) {
		printf("%s\n", lua_tostring(L, -1));
		lua_pop(L, 1);
	}
	lua_pop(L, 1);
}

namespace winhook {
	HWND m_window = NULL;
	HHOOK m_hook = NULL;
	UINT_PTR m_timer = 0;
	DWORD m_lasttick = 0;

	LRESULT __stdcall ProcGetMessage(int nCode, WPARAM wParam, LPARAM lParam)
	{
		PMSG pmsg = (PMSG)lParam;
		if (nCode == HC_ACTION && PM_NOREMOVE != wParam) 
		{
			if (m_window == pmsg->hwnd)
			{
				switch (pmsg->message)
				{
				case WM_DROPFILES:
					HANDLE_WM_DROPFILES(pmsg->hwnd, pmsg->wParam, pmsg->lParam, OnDropFiles);
					break;
				}
			}
		}
		return ::CallNextHookEx(m_hook, nCode, wParam, lParam);
	}

	void __stdcall ProcTimer(HWND hwnd, UINT uMsg, UINT_PTR idEvent, DWORD dwTime)
	{
		int delta = dwTime - m_lasttick;
		m_lasttick = dwTime;
		OnTimer(delta);
	}

	void start(HWND hwnd)
	{
		if (m_hook != NULL) return;
		m_window = hwnd;
		::DragAcceptFiles(m_window, TRUE);
		m_hook = ::SetWindowsHookExW(WH_GETMESSAGE, ProcGetMessage, NULL, ::GetWindowThreadProcessId(m_window, NULL));
		m_timer = ::SetTimer(m_window, 0, 16, ProcTimer);
		m_lasttick = ::GetTickCount();
	}

	void end()
	{
		if (m_hook == NULL) return;
		::DragAcceptFiles(m_window, FALSE);
		::UnhookWindowsHookEx(m_hook);
		::KillTimer(m_window, m_timer);
		m_hook = NULL;
		m_timer = 0;
	}
}

int register_window(lua_State* L) {
	std::wstring name = checkwstring(L, 1);
	gL = L;
	gW = ::FindWindowW(L"Yue_0", name.c_str());
	::ChangeWindowMessageFilterEx(gW, WM_DROPFILES, MSGFLT_ALLOW, nullptr);
  	::ChangeWindowMessageFilterEx(gW, 0x0049, MSGFLT_ALLOW, nullptr); 
	winhook::start(gW);
	return 0;
}

bool HideInTaskbar(HWND w)
{
	ITaskbarList* taskbar;
	if (SUCCEEDED(CoCreateInstance(CLSID_TaskbarList, NULL, CLSCTX_INPROC_SERVER, IID_ITaskbarList, (void**)&taskbar))) {
		taskbar->HrInit();
		taskbar->DeleteTab(w);
		taskbar->Release();
		return true;
	}
	return false;
}

int hide_in_taskbar(lua_State* L) {
	lua_pushboolean(L, HideInTaskbar(gW));
	return 1;
}

int set_icon(lua_State* L) {
	if (!winhook::m_window) {
		lua_pushboolean(L, false);
		return 1;
	}
	size_t len;
	const char* str = luaL_checklstring(L, 1, &len);
	std::wstring filename = u2w(std::string_view(str, len));
	HANDLE icon = LoadImageW(0, filename.c_str(), IMAGE_ICON, 0, 0, LR_LOADFROMFILE);
	if (!icon) {
		lua_pushboolean(L, false);
		return 1;
	}
	::SendMessageW(winhook::m_window, WM_SETICON, ICON_SMALL, (LPARAM)icon);
	::SendMessageW(winhook::m_window, WM_SETICON, ICON_BIG, (LPARAM)icon);
	::SendMessageW(winhook::m_window, WM_SETICON, ICON_SMALL2, (LPARAM)icon);
	lua_pushboolean(L, true);
	return 1;
}

extern "C" __declspec(dllexport)
int luaopen_ext(lua_State* L) {
	luaL_Reg lib[] = {
		{ "register_window", register_window },
		{ "hide_in_taskbar", hide_in_taskbar },
		{ "set_icon", set_icon },
		{ NULL, NULL },
	};
	luaL_newlib(L, lib);
	lua_pushvalue(L, -1);
	lua_rawsetp(L, LUA_REGISTRYINDEX, &EXT);
	return 1;
}
