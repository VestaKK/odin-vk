package renderer

import vk "vendor:vulkan"
import win32 "core:sys/windows"
import "core:fmt"
import "core:strings"

LARGE_INTEGER :: struct #raw_union {
    DUMMYSTRUCTNAME: struct {
        LowPart  : u32,
        HighPart : i32,
    },
    u: struct {
        LowPart  : u32,
        HighPart : i32,
    },
    QuadPart     : i64,
}

VulkanShader :: struct {
    file: []u8,
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
*/

win32_read_file :: proc(filename: string) -> (file: []u8, ok: bool) {

    file_handle := win32.CreateFileW(
        win32.utf8_to_wstring(filename), 
        win32.FILE_GENERIC_READ, 
        win32.FILE_SHARE_READ, 
        nil, 
        win32.OPEN_EXISTING, 
        0, 
        nil,
    )
    assert(file_handle != win32.INVALID_HANDLE_VALUE)
    defer win32.CloseHandle(file_handle)
    
    file_size: win32.LARGE_INTEGER
    win32.GetFileSizeEx(file_handle, &file_size) or_return
    
    content: win32.LPVOID
    file_size_u32 := safe_truncate_u64(u64(file_size))

    content = win32.VirtualAlloc(nil, uint(file_size_u32), win32.MEM_RESERVE | win32.MEM_COMMIT, win32.PAGE_READWRITE)
    assert(content != nil)
    // defer win32.VirtualFree(content, 0, win32.MEM_RELEASE) NOTE(MATT): Error Handling

    bytes_read: win32.DWORD
    win32.ReadFile(file_handle, content, file_size_u32, &bytes_read, nil) or_return
    assert(file_size_u32 == bytes_read)

    return (transmute([^]u8)content)[:file_size_u32], true
} 

create_shaders :: proc(using state: ^VulkanState) -> bool {

    vertex_info := vk.ShaderModuleCreateInfo {
        sType = .SHADER_MODULE_CREATE_INFO,
//	codeSize = file_result.content_size,
    }

    return true
}