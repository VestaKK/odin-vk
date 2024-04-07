package renderer

import vk "vendor:vulkan"

VulkanGraphicsPipeline :: struct {
    handle: vk.Pipeline,
}

create_graphics_pipeline :: proc(using state: ^VulkanState) -> bool {
    check(vk.CreateGraphicsPipelines(device.logical, {}, 0, nil, nil, nil)) or_return
    return true
}

destroy_graphics_pipeline :: proc(device: ^VulkanDevice, graphics_pipeline: ^VulkanGraphicsPipeline) {
    vk.DestroyPipeline(device.logical, graphics_pipeline.handle, nil)
}
