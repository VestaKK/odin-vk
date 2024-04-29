package renderer

import vk "vendor:vulkan"
import "base:runtime"
import "base:intrinsics"
import "core:fmt"

Error :: struct($T: typeid) {
    info: T,
    location: runtime.Source_Code_Location,
}

Message :: struct {
    message: string,
}

Vulkan :: struct {
    message: string,
    result: vk.Result,
}

Setup_Error :: union #shared_nil {
    ^Error(Message),
    ^Error(Vulkan),
}

error :: proc{
    error_custom,
    error_default,
}

error_custom :: proc(info: $T, location := #caller_location, allocator := context.temp_allocator) -> ^Error(T) 
    where T != string {
    err := new(Error(T), allocator)
    err^ = Error(T){info, location}
    return err
}

error_default :: proc(message: string, location := #caller_location, allocator := context.temp_allocator) -> ^Error(Message) {
    return error_custom(Message{message}, location, allocator)
}

error_print :: proc(format: string, location := #caller_location, allocator := context.temp_allocator, args: ..any) -> ^Error(Message) {
    return error_custom(Message{fmt.tprintf(format, args)}, location, allocator)
}

check :: proc{
    check_default,
    check_custom,
}

check_custom :: proc(result: vk.Result, message: string, location := #caller_location) -> ^Error(Vulkan) {
    return error(Vulkan{message, result})
}

check_default :: proc(result: vk.Result, location := #caller_location) -> ^Error(Vulkan) {
    if result == .SUCCESS do return nil
    return error(Vulkan{"Vulkan Error", result})
}

pass :: proc(result: vk.Result) -> bool {
    if result == .SUCCESS do return true
    else do return false
}