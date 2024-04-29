package renderer

import "core:fmt"
import vk "vendor:vulkan"
import "base:runtime"

check :: proc(result: vk.Result, location := #caller_location) -> bool {
    if result == .SUCCESS do return true
    fmt.eprintf("%v (%v): Vulkan Error [%v]\n", location.file_path, location.line, result)
    return false
}