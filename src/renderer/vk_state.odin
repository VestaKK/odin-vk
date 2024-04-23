package renderer

import vk "vendor:vulkan"
import "vendor:glfw"
import "core:os"
import "core:dynlib"
import "core:fmt"

// TODO(matt): Check if the library has to be unloaded at some point (probably but who knows tbh)
@(private)
vulkan_dynlib: dynlib.Library

VulkanState :: struct {

    window: struct {
        handle:             glfw.WindowHandle,
	    using dim: struct {
            width:          u32,
            height:         u32,
	    }
    },

    instance:               vk.Instance,
    surface:                vk.SurfaceKHR,
    // extent:         	    vk.Extent2D, // TODO(chowie): Extent?

    // NOTE(matt): only used for debugging
    debug_messenger:        vk.DebugUtilsMessengerEXT,
    device:                 VulkanDevice,
    swapchain:              VulkanSwapchain,
    shaders:                [Shader]VulkanShader,
    render_pass:            VulkanRenderPass,
    graphics_pipeline:      VulkanGraphicsPipeline,
}

// NOTE(matt): Loads vulkan lib at startup because that kinda just makes sense ig
load_vulkan_dynlib :: proc() -> bool {

    // NOTE(matt): Do not load dll again if it exists already
    if vulkan_dynlib != nil {
        return true
    } 

    // NOTE(matt): attempt to load dll into memory
    library, ok := dynlib.load_library("vulkan-1.dll")
    if !ok {
        fmt.eprintln(dynlib.last_error())
        return false
    }
    vulkan_dynlib = library

    // find vkGetInstanceProcAddr
    vk_get_instance_proc, found := dynlib.symbol_address(vulkan_dynlib, "vkGetInstanceProcAddr")
    if !found {
        fmt.eprintln(dynlib.last_error())
        return false
    }

    // NOTE(matt): Load global procedures only
    vk.load_proc_addresses_global(vk_get_instance_proc)

    return true
}

unload_vulkan_dynlib :: proc() {
    did_unload := dynlib.unload_library(vulkan_dynlib)
    if !did_unload {
        fmt.eprintf(dynlib.last_error())
    }
}

init_vulkan :: proc(state: ^VulkanState, window_handle: glfw.WindowHandle, width: u32, height: u32) -> bool { 

    //
    // Win32
    //

    // NOTE(chowie): Segregate Win32 out of the Vulkan state
    state.window.handle = window_handle
    state.window.dim = { width, height }

    //
    // 
    //

    // NOTE(matt): Load the vulkan-1.dll
    load_vulkan_dynlib() or_return
    create_instance(state) or_return
    create_surface(state) or_return 
    create_device(state) or_return
    create_swapchain(state) or_return
    create_shaders(state) or_return
    create_render_pass(state) or_return

    return true
}

shutdown :: proc(using state: ^VulkanState) {
    destroy_render_pass(&device, &render_pass)
    destroy_shaders(&device, &shaders)
    destroy_swapchain(&device, &swapchain)
    destroy_vulkan_device(&device)
    vk.DestroySurfaceKHR(instance, surface, nil)
    
    when ODIN_DEBUG {
        vk.DestroyDebugUtilsMessengerEXT(instance, debug_messenger, nil)
    }

    vk.DestroyInstance(instance, nil)
    unload_vulkan_dynlib()
}