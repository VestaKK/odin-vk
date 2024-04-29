package renderer

import vk "vendor:vulkan"
import "vendor:glfw"


create_surface :: proc(using state: ^VulkanState) -> (err: Setup_Error) { 
    check(glfw.CreateWindowSurface(instance, window.handle, nil, &surface)) or_return 
    return 
}

