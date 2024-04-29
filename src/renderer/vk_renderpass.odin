package renderer

import vk "vendor:vulkan"

VulkanRenderPass :: struct {
    handle: vk.RenderPass,
}

// TODO(Matt): Add Depth Buffer stuff after render triangle
VulkanAttachmentType :: enum {
    FrameBuffer,
    // Depth,
}

VulkanAttachment :: struct {
    type: VulkanAttachmentType,
    layout: vk.ImageLayout,
    desc: vk.AttachmentDescription,
}

record_attachment :: proc(
    attachments: ^[VulkanAttachmentType]vk.AttachmentDescription,
    attachment_refs: ^[VulkanAttachmentType]vk.AttachmentReference,
    attachment: VulkanAttachment) 
{
    attachments[attachment.type] = attachment.desc
    attachment_refs[attachment.type] = { u32(attachment.type), attachment.layout }
}

create_render_pass :: proc(using state: ^VulkanState) -> (err: Setup_Error) {

    attachments: [VulkanAttachmentType]vk.AttachmentDescription
    attachment_refs: [VulkanAttachmentType]vk.AttachmentReference
    color_attachment := VulkanAttachment{
        type = .FrameBuffer,
        layout = .COLOR_ATTACHMENT_OPTIMAL,
        desc = {
            format      = swapchain.format,
            samples     = {._1},
            loadOp      = .CLEAR,
            storeOp     = .STORE,
            stencilLoadOp = .CLEAR,
            stencilStoreOp = .STORE,
            initialLayout = .UNDEFINED,
            finalLayout = .PRESENT_SRC_KHR,
        }
    }
    record_attachment(&attachments, &attachment_refs, color_attachment)
/*    
    depth_attachment := VulkanAttachment{
        type = .Depth,
        layout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        desc = {
            format      = .D24_UNORM_S8_UINT,
            samples     = {._1},
            loadOp      = .CLEAR,
            storeOp     = .STORE,
            stencilLoadOp = .CLEAR,
            stencilStoreOp = .STORE,
            initialLayout = .UNDEFINED,
            finalLayout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        }
    }
    record_attachment(&attachments, &attachment_refs, depth_attachment)
*/
    sub_pass_description := vk.SubpassDescription{
        pipelineBindPoint = .GRAPHICS,
        colorAttachmentCount = 1,
        pColorAttachments = &attachment_refs[.FrameBuffer],
	    //pDepthStencilAttachment = &attachment_refs[.Depth],
    }

    // NOTE(MATT): do subpass dependencies
    create_info := vk.RenderPassCreateInfo{
        sType = .RENDER_PASS_CREATE_INFO,
        attachmentCount = len(attachments),
        pAttachments = ([^]vk.AttachmentDescription)(&attachments),
        subpassCount = 1,
        pSubpasses = &sub_pass_description,
    }
    check(vk.CreateRenderPass(device.handle, &create_info, nil, &render_pass.handle)) or_return

    return
}

destroy_render_pass :: proc(device: ^VulkanDevice, render_pass: ^VulkanRenderPass) {
    vk.DestroyRenderPass(device.handle, render_pass.handle, nil)
}
