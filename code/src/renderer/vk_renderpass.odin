package renderer

import vk "vendor:vulkan"

VulkanRenderPass :: struct {
    internal: vk.RenderPass,
}

create_render_pass :: proc(using state: ^VulkanState) -> bool { 
    colour_attachment_description := vk.AttachmentDescription{
        format      = swapchain.format,
        samples     = {._1},
        loadOp      = .CLEAR,
        storeOp     = .STORE,
        stencilLoadOp = .DONT_CARE,
        stencilStoreOp = .DONT_CARE,
        initialLayout = .UNDEFINED,
        finalLayout = .PRESENT_SRC_KHR,
    }

    colour_attackment_ref := vk.AttachmentReference{
        attachment  = 0,
        layout      = .COLOR_ATTACHMENT_OPTIMAL,
    }

    sub_pass_description := vk.SubpassDescription{
        pipelineBindPoint = .GRAPHICS,
        colorAttachmentCount = 1,
        pColorAttachments = &colour_attackment_ref,
    }

    // NOTE(MATT): do subpass dependencies

    render_pass_create_info := vk.RenderPassCreateInfo{
        sType = .RENDER_PASS_CREATE_INFO,
        attachmentCount = 1,
        pAttachments = &colour_attachment_description,
        subpassCount = 1,
        pSubpasses = &sub_pass_description,
    }

    check(vk.CreateRenderPass(device.logical, &render_pass_create_info, nil, &render_pass.internal)) or_return
    return true
}

destroy_render_pass :: proc(device: ^VulkanDevice, render_pass: ^VulkanRenderPass) {
    vk.DestroyRenderPass(device.logical, render_pass.internal, nil)
}
