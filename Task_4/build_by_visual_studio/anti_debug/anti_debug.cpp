#include <stdio.h>
#include <windows.h>
#include <winternl.h>

#define NtCurrentThread ((HANDLE)-2)
typedef NTSTATUS(WINAPI* pNtSetInformationThread)(HANDLE, THREAD_INFORMATION_CLASS, PVOID, ULONG);

#ifndef ThreadHideFromDebugger
#define ThreadHideFromDebugger 0x11
#endif

void check_isDebuggerPresent() {
	if (IsDebuggerPresent()) {
		printf("Detected by IsDebuggerPresent\n");
	}
	else
		printf("X");
}

void check_PEB() {
	PPEB pPeb = (PPEB)__readgsqword(0x60);
	if (pPeb->BeingDebugged) {
		printf("Detected by PEB\n");
	}
	else
		printf("i");
}

bool check3() {
	__try
	{
		CloseHandle((HANDLE)0xDEADBEEF);
		return false;
	}
	__except (EXCEPTION_INVALID_HANDLE == GetExceptionCode()
		? EXCEPTION_EXECUTE_HANDLER
		: EXCEPTION_CONTINUE_SEARCH)
	{
		return true;
	}
}

void check_closeHandle() {
	if (check3()) {
		printf("Detected by CloseHandle\n");
	}
	else
		printf("n");
}

bool check4() {
	__try {
		RaiseException(DBG_CONTROL_C, 0, 0, NULL);
		return true;
	}
	__except (DBG_CONTROL_C == GetExceptionCode()
		? EXCEPTION_EXECUTE_HANDLER
		: EXCEPTION_CONTINUE_SEARCH)
	{
		return false;
	}
}

void check_raiseException() {
	if (check4()) {
		printf("Detected by RaiseException\n");
	}
	else
		printf(" ");
}

void check_getLocalTime() {
	SYSTEMTIME st;
	DWORD start, end, diff;
	GetLocalTime(&st);
	start = GetTickCount64();
	GetLocalTime(&st);
	end = GetTickCount64();
	diff = end - start;
	if (diff > 5) {
		printf("Detected by timing\n");
	}
	else
		printf("C");
}

bool check6() {
	CONTEXT ctx;
	ZeroMemory(&ctx, sizeof(CONTEXT));
	ctx.ContextFlags = CONTEXT_DEBUG_REGISTERS;
	if (!GetThreadContext(GetCurrentThread(), &ctx))
		return false;
	return ctx.Dr0 || ctx.Dr1 || ctx.Dr2 || ctx.Dr3;
}

void check_hardwareBr() {
	if (check6()) {
		printf("Detected by hardware breakpoints\n");
	}
	else
		printf("h");
}

bool check7() {
	__try {
		DebugBreak();
	}
	__except (EXCEPTION_BREAKPOINT == GetExceptionCode()) {
		return false;
	}
	return true;
}

void check_debugBreak() {
	if (check7()) {
		printf("Detected by DebugBreak\n");
	}
	else
		printf("a");
}

bool check8() {
	HMODULE hNtdll = GetModuleHandleA("ntdll.dll");
	if (!hNtdll) {
		return false;
	}

	pNtSetInformationThread NtSetInformationThread = (pNtSetInformationThread)GetProcAddress(
		hNtdll, "NtSetInformationThread");

	if (!NtSetInformationThread) {
		return false;
	}

	NTSTATUS status = NtSetInformationThread(
		NtCurrentThread,
		(THREAD_INFORMATION_CLASS)ThreadHideFromDebugger,
		NULL,
		0);

	return status >= 0;
}

void check_selfDebug() {
	if (!check8()) {
		printf("Detected by ThreadHideFromDebugger\n");
	}
	else
		printf("o");
}

bool check9() {
	return FindWindowA("Qt5QWindowIcon", NULL) ||  // x64dbg, IDA 7.x
		FindWindowA("OllyDbg", NULL) ||        // OllyDbg
		FindWindowA("IDAW", NULL);             // IDA Pro (v6.x)
}

void check_debuggerWin() {
	if (check9()) {
		printf("Detected by CheckDebuggerWindows\n");
	}
	else
		printf("!\nKo thay debug :))\n");
}

int main() {
	check_isDebuggerPresent();
	check_PEB();
	check_closeHandle();
	check_raiseException();
	check_getLocalTime();
	check_hardwareBr();
	check_debugBreak();
	check_selfDebug();
	check_debuggerWin();
	return 0;
}