package renderer

import vk "vendor:vulkan"
import "core:fmt"

VulkanDevice :: struct {
    physical:               vk.PhysicalDevice,
    logical:                vk.Device,
    swapchain_support_info: VulkanSwapchainSupportInfo, 
    graphics_queue_index:   u32,
    present_queue_index:    u32,
    graphics_queue:         vk.Queue,   
    present_queue:          vk.Queue,
    command_pool:           vk.CommandPool,
}

VulkanDeviceTypes :: distinct [vk.PhysicalDeviceType]bool

VulkanPhysicalDeviceRequirements :: struct {
    allowed_devices: VulkanDeviceTypes,
    graphics: bool,
    present:  bool,
    extensions: []cstring,
    swapchain_support: bool,
}

VulkanQueueFamilyInfo :: struct {
    graphics_queue_index: i32,
    present_queue_index: i32,
}

VulkanSwapchainSupportInfo :: struct {
    capabilites:    vk.SurfaceCapabilitiesKHR,
    formats:        []vk.SurfaceFormatKHR,
    present_modes:  []vk.PresentModeKHR,
}

enabled_device_extensions :: []cstring{
    vk.KHR_SWAPCHAIN_EXTENSION_NAME, // NOTE(chowie): Manadatory for displaying a window
}

physical_device_get_swapchain_support :: proc(
    physical_device: vk.PhysicalDevice,
    surface: vk.SurfaceKHR,
    queue_family_index: u32
) -> (
    swapchain_support_info: VulkanSwapchainSupportInfo,
    supported: bool
) {
    // NOTE(matt): Check for surface support

    is_supported: b32
    check(vk.GetPhysicalDeviceSurfaceSupportKHR(physical_device, queue_family_index, surface, &is_supported)) or_return
    if !is_supported {
        return {}, false
    }

    // NOTE(matt): Populate swapchain_support_info
    capabilities: vk.SurfaceCapabilitiesKHR
    check(vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(physical_device, surface, &capabilities)) or_return

    // NOTE(matt): Formats
    format_count: u32
    check(vk.GetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &format_count, nil)) or_return
    formats := make([]vk.SurfaceFormatKHR, format_count)
    check(vk.GetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &format_count, raw_data(formats))) or_return

    // NOTE(matt): Surface Present Modes
    mode_count: u32
    check(vk.GetPhysicalDeviceSurfacePresentModesKHR(physical_device, surface, &mode_count, nil)) or_return
    present_modes := make([]vk.PresentModeKHR, mode_count)
    check(vk.GetPhysicalDeviceSurfacePresentModesKHR(physical_device, surface, &mode_count, raw_data(present_modes))) or_return

    return {capabilities, formats, present_modes}, bool(is_supported)
}

physical_device_meets_requirements :: proc(
    physical_device:    vk.PhysicalDevice,
    surface:            vk.SurfaceKHR,
    properties:         vk.PhysicalDeviceProperties,
    features:           vk.PhysicalDeviceFeatures,
    requirements:       VulkanPhysicalDeviceRequirements,
) -> (
    queue_family_info:      VulkanQueueFamilyInfo,
    swapchain_support_info: VulkanSwapchainSupportInfo,
    is_suitable:            bool,
) {
  
    if !requirements.allowed_devices[properties.deviceType] {
        return {}, {}, false
    }

    // NOTE(matt): Check extension support
    extension_count: u32
    check(vk.EnumerateDeviceExtensionProperties(physical_device, nil, &extension_count, nil)) or_return
    extension_properties := make([]vk.ExtensionProperties, extension_count)
    defer delete(extension_properties)
    check(vk.EnumerateDeviceExtensionProperties(physical_device, nil, &extension_count, raw_data(extension_properties))) or_return
    outer: for &required in requirements.extensions {
        for &extension in extension_properties {
            extension_name := cstring(raw_data(extension.extensionName[:]))
            if required == extension_name {
                continue outer
            }
        }
        return {}, {}, false
    }

    queue_family_info = {-1, -1}
    queue_family_count: u32
    vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_count, nil)
    queue_family_properties := make([]vk.QueueFamilyProperties, queue_family_count)
    defer delete(queue_family_properties)
    vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_count, raw_data(queue_family_properties))

    for &queue_family_property, queue_family_index in queue_family_properties {
        if (queue_family_info.graphics_queue_index == -1 &&
            requirements.graphics) {
            if .GRAPHICS in queue_family_property.queueFlags {
                queue_family_info.graphics_queue_index = i32(queue_family_index)
            }
        }

        if (queue_family_info.present_queue_index == -1 &&
            requirements.present) {
            swapchain_support_info = physical_device_get_swapchain_support(physical_device, surface, u32(queue_family_index)) or_break
            queue_family_info.present_queue_index = i32(queue_family_index)
        }

        // NOTE(matt): If we have found a queue family for both, return 
        if queue_family_info.graphics_queue_index != -1 &&
            queue_family_info.present_queue_index != -1 { 
            return queue_family_info, swapchain_support_info, true
        }
    }

    // NOTE(matt): Couldn't find indices for the graphics and present queues
    return {}, {}, false
} 

select_physical_device :: proc(using state: ^VulkanState) -> bool {

    physical_device_count: u32
    check(vk.EnumeratePhysicalDevices(instance, &physical_device_count, nil)) or_return
    assert(physical_device_count != 0)

    physical_devices := make([]vk.PhysicalDevice, physical_device_count)
    defer delete(physical_devices)
    check(vk.EnumeratePhysicalDevices(instance, &physical_device_count, raw_data(physical_devices))) or_return
    // TODO(chowie): Do we need VK_INCOMPLETE for checking?

    for &physical_device in physical_devices {
        properties: vk.PhysicalDeviceProperties
        vk.GetPhysicalDeviceProperties(physical_device, &properties)

        features: vk.PhysicalDeviceFeatures
        vk.GetPhysicalDeviceFeatures(physical_device, &features)

	// NOTE(chowie): Main types of memory is "host visible" (RAM)
	// and "device local" (GPU Memory). Returning memory requirements
	// starts from LSB, useful for vertex buffers and textures.
	memory_properties: vk.PhysicalDeviceMemoryProperties
        vk.GetPhysicalDeviceMemoryProperties(physical_device, &memory_properties)

        requirements := VulkanPhysicalDeviceRequirements{
            allowed_devices = {
                .DISCRETE_GPU = true,
                .INTEGRATED_GPU = true,
                .CPU = false,
                .OTHER = false,
                .VIRTUAL_GPU = false,
            },
            graphics = true,
            present = true,
            extensions = enabled_device_extensions,
        }
        
        // NOTE(matt): Check that device meets requirements
        queue_family_info, swapchain_support_info := physical_device_meets_requirements(physical_device, surface, properties, features, requirements) or_continue

        // NOTE(matt): Queue family stuff
        device.physical = physical_device
        device.graphics_queue_index = u32(queue_family_info.graphics_queue_index)
        device.present_queue_index = u32(queue_family_info.graphics_queue_index)
        device.swapchain_support_info = swapchain_support_info

        fmt.printf("%#v\n%#v\n", queue_family_info, swapchain_support_info)
        return true
    }

    return false
}

create_device :: proc(using state: ^VulkanState) -> bool {
    select_physical_device(state) or_return
    single_queue := device.graphics_queue_index == device.present_queue_index

    if !single_queue {
        fmt.println("We don't support separate graphics and present queues lol")
        return false
    }

    // TODO(chowie): Single-threaded application for now.
    queue_priority := f32(1)
    queue_create_info := vk.DeviceQueueCreateInfo{
        sType = .DEVICE_QUEUE_CREATE_INFO,
        queueFamilyIndex = device.graphics_queue_index,
        queueCount = 1,
        pQueuePriorities = &queue_priority,
    }

    device_create_info := vk.DeviceCreateInfo{
        sType = .DEVICE_CREATE_INFO,
        queueCreateInfoCount = 1,
        pQueueCreateInfos = &queue_create_info,
        enabledExtensionCount = u32(len(enabled_device_extensions)),
        ppEnabledExtensionNames = raw_data(enabled_device_extensions),
	// TODO(chowie): Usually you want to pass pEnabledFeatures inside here with PhysicalDeviceFeatures()! Otherwise, passing 0 disables features
    }

    check(vk.CreateDevice(device.physical, &device_create_info, nil, &device.logical)) or_return
    vk.load_proc_addresses_device(device.logical)
    vk.GetDeviceQueue(device.logical, device.graphics_queue_index, 0, &device.graphics_queue) 
    vk.GetDeviceQueue(device.logical, device.present_queue_index, 0, &device.present_queue)
    assert(device.graphics_queue == device.present_queue && device.graphics_queue != nil)

    command_pool_create_info := vk.CommandPoolCreateInfo{
        sType = .COMMAND_POOL_CREATE_INFO,
        flags = {.TRANSIENT},
        queueFamilyIndex = device.graphics_queue_index,
    }
    vk.CreateCommandPool(device.logical, &command_pool_create_info, nil, &device.command_pool)

    return true
}

destroy_vulkan_device :: proc(using device: ^VulkanDevice) {

    vk.DestroyCommandPool(device.logical, device.command_pool, nil)
    delete(swapchain_support_info.formats)
    delete(swapchain_support_info.present_modes)
    vk.DestroyDevice(logical, nil)
}