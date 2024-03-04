package renderer

import vk "vendor:vulkan"
import "core:fmt"
import "core:strings"

// TODO(chowie): Move this to win32

LPCSTR :: cstring;
LPVOID :: rawptr;

INT  :: i32;
UINT :: u32;
PUINT:: ^u32;
UINT_PTR :: u64;
ULONG :: u32;
LONG :: i32;
LONGLONG :: i64;
BOOL  :: b32; 
WORD  :: u16;
DWORD :: u32;
DWORD_PTR :: ^u32;
ATOM :: WORD;
BYTE :: byte;
SHORT :: i16;
USHORT :: u16;

LPSTR :: ^u8;
LONG_PTR  :: i64; 
ULONG_PTR :: u64;
LPSECURITY_ATTRIBUTES :: LONG_PTR;
LRESULT   :: LONG_PTR;
WPARAM    :: UINT_PTR;
LPARAM    :: LONG_PTR;
SIZE_T    :: ULONG_PTR;

HMODULE   :: distinct rawptr;
HINSTANCE :: distinct rawptr;
HCURSOR   :: distinct rawptr;
HICON     :: distinct rawptr;
HBRUSH    :: distinct rawptr;
HWND      :: distinct rawptr;
HMENU     :: distinct rawptr;
HDC       :: distinct rawptr;
HRGN      :: distinct rawptr;
HRAWINPUT :: distinct rawptr;
HANDLE    :: distinct rawptr;

MEM_COMMIT :: 0x00001000;
MEM_RESERVE :: 0x00002000;
PAGE_READWRITE :: 0x04;
FILE_SHARE_READ :: 0x00000001;
// RESOURCE: https://learn.microsoft.com/en-us/windows/win32/secauthz/access-mask
// TODO(chowie): GENERIC_READ
OPEN_EXISTING :: 3;

LARGE_INTEGER :: struct #raw_union {
    DUMMYSTRUCTNAME: struct {
        LowPart  : DWORD,
        HighPart : LONG
    },
    u: struct {
        LowPart  : DWORD,
        HighPart : LONG
    },
    QuadPart     : LONGLONG
};

foreign import kernel "system:kernel32.lib"
@(default_calling_convention = "std")
foreign kernel {

	// RESOURCE: https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilea
	CreateFileA :: proc(
		lpFileName: LPCSTR,
		dwDesiredAccess: DWORD,
		dwShareMode: DWORD,
		lpSecurityAttributes: LPSECURITY_ATTRIBUTES,
		dwCreationDisposition: DWORD,
		dwFlagsAndAttributes: DWORD,
		hTemplateFile: HANDLE,
	) -> HANDLE ---;

	// RESOURCE: https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getfilesizeex
	GetFileSizeEx :: proc(
		hFile: HANDLE,
		lpFileSize: ^LARGE_INTEGER, // NOTE(chowie): Wants PLARGE_INTEGER
	) -> BOOL ---;

	// TODO(chowie): VirtualAlloc does not work?
/*
	// RESOURCE: https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualalloc
	VirtualAlloc :: proc(
	   lpAddress: LPVOID,
	   dwSize: SIZE_T,
           flAllocationType: DWORD,
           flProtect: DWORD,
        ) -> LPVOID ---;
*/
}

// TODO(chowie): Move this out into win32!
DebugFileReadResult :: struct {
    content_size: u32,
    contents: rawptr,
}

VulkanShader :: struct {
    file_result: DebugFileReadResult,
}

safe_truncate_u64 :: proc(value: u64) -> u32 {
     // TODO(chowie): Defines for maximum values
     assert(value <= 0xFFFFFFFF)
     result := u32(value)
     return result
}

/*
// TODO(chowie): Double check this all compiles well!
// TODO(chowie): Ask Matt if there's equivalent windows lib in odin!
win32_read_file :: proc(filename: cstring) -> DebugFileReadResult {

    result := DebugFileReadResult {}

    file_handle : HANDLE = CreateFileA(filename, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, 0, 0);
    if file_handle != INVALID_HANDLE_VALUE
    {
       file_size: LARGE_INTEGER
       if GetFileSizeEx(file_handle, &file_size)
       {
	   file_size32 : u32 = safe_truncate_u64(u64(file_size.QuadPart))
	   result.contents = VirtualAlloc(0, file_size32, MEM_RESERVE|MEM_COMMIT, PAGE_READWRITE)
	   // TODO(chowie): How do I check if result.contents is valid as a rawptr?
	   if result.contents
	   {
		bytes_read: DWORD
		if ReadFile(file_handle, result.contents, file_size32, &bytes_read, 0) && (file_size32 == bytes_read)
		{
		    result.contents = file_size32
		}
		else
		{
		    VirtualFree(result.contents, 0, MEM_RELEASE)
                    result.contents = 0
		}
	   }
       }
       CloseHandle(file_handle)
    }

    return result
}
*/

create_shaders :: proc(using state: ^VulkanState) -> bool {

    vertex_info := vk.ShaderModuleCreateInfo {
        sType = .SHADER_MODULE_CREATE_INFO,
//	codeSize = file_result.content_size,
    }

    return true
}