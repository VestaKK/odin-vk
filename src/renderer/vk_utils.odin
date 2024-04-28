package renderer

import "core:fmt"
import vk "vendor:vulkan"

check_with_exceptions :: #force_inline proc(result: vk.Result, other: map[vk.Result]bool, location := #caller_location) -> bool {
    if result == .SUCCESS || other[result] {
        return true
    }
    fmt.eprintf("%v (%v): Vulkan Error [%v]\n", location.file_path, location.line, result)
    return false
}

check_success :: #force_inline proc(result: vk.Result, location := #caller_location) -> bool {
    if result == .SUCCESS {
        return true
    }
    
    fmt.eprintf("%v (%v): Vulkan Error [%v]\n", location.file_path, location.line, result)
    return false
}

check :: proc{
    check_success,
    check_with_exceptions,
}