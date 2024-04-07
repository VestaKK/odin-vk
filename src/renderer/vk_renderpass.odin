package renderer

import vk "vendor:vulkan"

VulkanRenderPass :: struct {
    internal: vk.RenderPass,
}


create_render_pass :: proc(using state: ^VulkanState) -> bool {

    attachments: struct #raw_union {
        using _ : struct {
            color: vk.AttachmentDescription,
            depth: vk.AttachmentDescription,
        },
        all: [2]vk.AttachmentDescription,   
    }

    attachments.color = {
        format      = swapchain.format,
        samples     = {._1},
        loadOp      = .CLEAR,
        storeOp     = .STORE,
        stencilLoadOp = .CLEAR,
        stencilStoreOp = .STORE,
        initialLayout = .UNDEFINED,
        finalLayout = .PRESENT_SRC_KHR,
    }

    attachments.depth = {
        format      = .D24_UNORM_S8_UINT,
        samples     = {._1},
        loadOp      = .CLEAR,
        storeOp     = .STORE,
        stencilLoadOp = .CLEAR,
        stencilStoreOp = .STORE,
        initialLayout = .UNDEFINED,
        finalLayout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
    }

    colour_attachment_ref := vk.AttachmentReference{
        attachment  = 0, // Colour Index
        layout      = .COLOR_ATTACHMENT_OPTIMAL,
    }

    depth_attachment_ref := vk.AttachmentReference{
        attachment  = 1, // Depth Index
        layout      = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
    }

    sub_pass_description := vk.SubpassDescription{
        pipelineBindPoint = .GRAPHICS,
        colorAttachmentCount = 1,
        pColorAttachments = &colour_attachment_ref,
	    pDepthStencilAttachment = &depth_attachment_ref,
    }

    // NOTE(MATT): do subpass dependencies

    render_pass_create_info := vk.RenderPassCreateInfo{
        sType = .RENDER_PASS_CREATE_INFO,
        attachmentCount = u32(len(attachments.all)),
        pAttachments = raw_data(attachments.all[:]),
        subpassCount = 1,
        pSubpasses = &sub_pass_description,
    }

    check(vk.CreateRenderPass(device.logical, &render_pass_create_info, nil, &render_pass.internal)) or_return
    return true
}

destroy_render_pass :: proc(device: ^VulkanDevice, render_pass: ^VulkanRenderPass) {
    vk.DestroyRenderPass(device.logical, render_pass.internal, nil)
}
