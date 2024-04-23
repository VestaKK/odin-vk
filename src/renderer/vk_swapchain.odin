package renderer

import vk "vendor:vulkan"
import "core:fmt"

VulkanSwapchain :: struct {
    handle:         vk.SwapchainKHR,
    format:         vk.Format,
    extent:         vk.Extent2D,
    viewport:       vk.Viewport,
    scissor:        vk.Rect2D,
    colour_space:   vk.ColorSpaceKHR,
    images:         []vk.Image,
    image_views:    []vk.ImageView,
    // framebuffers:   []vk.Framebuffer,
    // semaphore:      vk.Semaphore,
}

create_swapchain :: proc(using state: ^VulkanState) -> bool {

    // NOTE(matt): Check swapchain supports image format
    // TODO(chowie): _Block for 4x4 reading, or _PACK32?
    swapchain.format = vk.Format.B8G8R8A8_SRGB
    swapchain.colour_space = vk.ColorSpaceKHR.SRGB_NONLINEAR
    swapchain.extent = device.swapchain_support_info.capabilites.currentExtent

    // RESOURCE: https://ciechanow.ski/alpha-compositing/
    queue_family_indicies := []u32 { device.graphics_queue_index }
    swapchain_create_info := vk.SwapchainCreateInfoKHR{
        sType                   = .SWAPCHAIN_CREATE_INFO_KHR,
        surface                 = surface,
        minImageCount           = 2, // NOTE(chowie): Supports double buffering at a minimum
        imageFormat             = swapchain.format,
        imageColorSpace         = swapchain.colour_space,
        imageExtent             = swapchain.extent,
        imageArrayLayers        = 1,
        imageUsage              = {.COLOR_ATTACHMENT},
        queueFamilyIndexCount   = cast(u32) len(queue_family_indicies),
        pQueueFamilyIndices     = raw_data(queue_family_indicies),
        preTransform            = device.swapchain_support_info.capabilites.currentTransform,
        compositeAlpha          = {.OPAQUE}, // TODO(chowie): .Premultiplied sRGB
        presentMode             = .FIFO,
        clipped                 = true,
        oldSwapchain            = {}, // TODO(chowie): Required if creating a new swapchain to replace an old one, like resizing a window
    }

    check(vk.CreateSwapchainKHR(device.handle, &swapchain_create_info, nil, &swapchain.handle)) or_return
    swapchain.viewport = vk.Viewport{
        x = 0,
        y = 0,
        minDepth = 0.0,
        maxDepth = 1.0,
        width = f32(swapchain.extent.width),
        height = f32(swapchain.extent.height),
    }
    swapchain.scissor = vk.Rect2D{
        offset = {},
        extent = swapchain.extent 
    }
    // NOTE(matt): Technically we should clean up on failure but this is like taking a piss in an ocean
    image_count := u32(2)
    swapchain.images = make([]vk.Image, image_count)
    swapchain.image_views = make([]vk.ImageView, image_count)
    // swapchain.framebuffers = make([]vk.Framebuffer, image_count) 
    check(vk.GetSwapchainImagesKHR(device.handle, swapchain.handle, &image_count, raw_data(swapchain.images))) or_return

    // TODO(chowie): I'd be interested to see if we can do our own swizzle components
    for &image, index in swapchain.images {
        image_view_create_info := vk.ImageViewCreateInfo{
            sType               = .IMAGE_VIEW_CREATE_INFO,
            image               = image,
            viewType            = .D2,
            format              = swapchain.format,
            components          = {
                r = .R,
                g = .G,
                b = .B,
                a = .A,
            },
            subresourceRange    = {
                aspectMask      = {.COLOR},
                baseMipLevel    = 0,
                levelCount      = 1,
                baseArrayLayer  = 0,
                layerCount      = 1,
            },
        } 
        check(vk.CreateImageView(device.handle, &image_view_create_info, nil, &swapchain.image_views[index] )) or_return
    }
/*
    semaphore_create_info := vk.SemaphoreCreateInfo {
    	sType = .SEMAPHORE_CREATE_INFO,
    }

    check(vk.CreateSemaphore(device.handle, &semaphore_create_info, nil, &swapchain.semaphore )) or_return
*/
    return true
}

recreate_swapchain :: proc(using state: ^VulkanState) -> bool {

    // NOTE(chowie): Recreate on window resize
    // vk.DeviceWaitIdle(device.logical);
    // destroy_swapchain(&device, &swapchain);
    // state.window.dim = {}

    return true
}

destroy_swapchain :: proc(device: ^VulkanDevice, using swapchain: ^VulkanSwapchain) { 

    
    // vk.DestroySemaphore(device.handle, swapchain.semaphore, nil)
    /*
    for &framebuffer in framebuffers {
        vk.DestroyFramebuffer(device.handle, framebuffer, nil)
    }
    */

    for &image_view in image_views {
        vk.DestroyImageView(device.handle, image_view, nil)
    }

    // delete(framebuffers)
    delete(image_views)    
    delete(images)
    vk.DestroySwapchainKHR(device.handle, handle, nil)
}
