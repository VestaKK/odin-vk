package renderer

import "core:fmt"
import vk "vendor:vulkan"

// TODO(chowie): This should probably be segregated by Graphics API with #define
check_with_exceptions :: #force_inline proc(result: vk.Result, accepted: []vk.Result, location := #caller_location) -> bool {
    
    for &acc in accepted {
        if result == acc {
            return true
        }
    }

    fmt.eprintf("%v (%v): Vulkan Error [%v]\n", location.file_path, location.line, result)
    return false
}

// TODO(matt): Maybe swap the location parameter
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