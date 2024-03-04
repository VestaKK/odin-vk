package renderer

import "base:runtime"
import vk "vendor:vulkan"
import "core:fmt"
import "core:strings"

// TODO(chowie): This should probably we moved out to have a unified
// "debug" file, so that it can be easily segregated from the file

// NOTE(chowie): This is a list of layers we would like, but is not
// strictly neccessary!
when ODIN_DEBUG do enabled_layers :: []cstring { "VK_LAYER_KHRONOS_validation", }

// TODO(matt): Sorta temporary, ideally we have a platform thing for this tbh
// TODO(chowie): This really feels like this should be segregate by mandatory and desired!
enabled_instance_extensions :: []cstring{
    vk.KHR_SURFACE_EXTENSION_NAME, // NOTE(chowie): Mandatory for outputting a window or "surface"
    vk.KHR_WIN32_SURFACE_EXTENSION_NAME, // TODO(chowie): Segregate this with #define VK_USE_PLATFORM_WIN32_KHR ideally

    //
    // Debug
    //

    vk.EXT_DEBUG_UTILS_EXTENSION_NAME, // TODO(chowie): Use this! And only set with ODIN_DEBUG. And technically, this is deprecated too as of 1.3, should be "VK_EXT_debug_utils"
}

// TODO(chowie): I've made callbacks in the past, this is where I'd use #define
// cast the function into a type -> added in vulkan-specific struct.
// Ask Matt if he wants to try this!
debug_utils_messenger_callback :: proc "system" (
    messageSeverity: vk.DebugUtilsMessageSeverityFlagsEXT,
    messageTypes: vk.DebugUtilsMessageTypeFlagsEXT,
    pCallbackData: ^vk.DebugUtilsMessengerCallbackDataEXT, 
    pUserData: rawptr
) -> b32 {

    context = runtime.default_context()
    severity_map := map[vk.DebugUtilsMessageSeverityFlagEXT]rune{
        .VERBOSE = 'V',
        .INFO = 'I',
        .WARNING = 'W',
        .ERROR = 'E',
    }

    severity_index := map[vk.DebugUtilsMessageSeverityFlagEXT]int{
        .VERBOSE = 0,
        .INFO = 1,
        .ERROR = 2,
        .WARNING = 3,
    }

    builder := strings.builder_make_len(4)
    defer strings.builder_destroy(&builder)
    for severity in vk.DebugUtilsMessageSeverityFlagEXT {
        if letter := severity_map[severity]; severity in messageSeverity {
            strings.write_encoded_rune(&builder, letter, write_quote=false)
        } else {
            strings.write_encoded_rune(&builder, '_', write_quote=false)
        }
    }
    severity_string := strings.to_string(builder)

    fmt.printf("[%v] - %v: %v\n", severity_string, pCallbackData.pMessageIdName, pCallbackData.pMessage)
    return true
}

check_layer_support :: proc(requested_layers: []cstring) -> bool {

    layer_count: u32
    check(vk.EnumerateInstanceLayerProperties(&layer_count, nil)) or_return
    instance_layers := make([]vk.LayerProperties, layer_count)
    defer delete(instance_layers)
    check(vk.EnumerateInstanceLayerProperties(&layer_count, raw_data(instance_layers))) or_return

    // TODO(chowie): Ask matt what "outer:" here means exactly?
    outer: for &requested in  requested_layers {
        for &existing in instance_layers {
            if requested == cstring(raw_data(existing.layerName[:])) {
                continue outer
            }
        }
        return false
    }
    return true
}

create_instance :: proc(using state: ^VulkanState) -> bool {

    application_info := vk.ApplicationInfo {
        sType = .APPLICATION_INFO,
        pApplicationName = "Vulkan Demo",
        applicationVersion = 1,
        pEngineName = "An Engine",
        engineVersion = 1,
        apiVersion = vk.MAKE_VERSION(1,3,0),
    }

    instance_create_info := vk.InstanceCreateInfo {
        sType = .INSTANCE_CREATE_INFO,
        pApplicationInfo = &application_info,
    }

    when ODIN_DEBUG { 

        // NOTE(matt): Validation support imples existence of debug utils messenger
        check_layer_support(enabled_layers) or_return

        // NOTE(matt): Debug util stuff
        debug_messenger_utils_create_info := vk.DebugUtilsMessengerCreateInfoEXT{
            sType = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
            messageSeverity  = {
                .WARNING,
                .ERROR,
            },
            messageType = {
                .VALIDATION, 
                .GENERAL,
            },
            pfnUserCallback = debug_utils_messenger_callback,
        }

        // TODO(matt): Extend create_info to deal with validation layers
        instance_create_info.enabledLayerCount = cast(u32) len(enabled_layers)
        instance_create_info.ppEnabledLayerNames = raw_data(enabled_layers)

        // NOTE(matt): Enabled instance extensions come with debug utils messenger
        instance_create_info.enabledExtensionCount = cast(u32) len(enabled_instance_extensions)
        instance_create_info.ppEnabledExtensionNames = raw_data(enabled_instance_extensions)
        instance_create_info.pNext = &debug_messenger_utils_create_info

    } else {

        // NOTE(matt): Debug utils is the last extension, so we reduce the count to disinclude it
        instance_create_info.enabledExtensionCount = cast(u32) (len(enabled_instance_extensions) - 1)
        instance_create_info.ppEnabledExtensionNames = raw_data(enabled_instance_extensions) 
    }

    // TODO(chowie): We have no need for extension array, probably should be freed! Memory arena?

    // NOTE(matt): Create instance and load function pointers
    check(vk.CreateInstance(&instance_create_info, nil, &instance)) or_return   
    vk.load_proc_addresses_instance(state.instance)

    when ODIN_DEBUG {
        check(vk.CreateDebugUtilsMessengerEXT(instance, &debug_messenger_utils_create_info, nil, &debug_messenger)) or_return
    }

    return true
}