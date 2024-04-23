package renderer

import vk "vendor:vulkan"
import "core:math/linalg"
import "core:reflect"
VulkanGraphicsPipeline :: struct {
    handle: vk.Pipeline,
	layout: vk.PipelineLayout,
}

Vertex :: struct {
	pos: linalg.Vector3f32,
	color: linalg.Vector3f32,
}
vertices := []Vertex{
	{pos =  { 0.0, -0.5,  0.0}, color = {1.0, 0.0, 0.0}},
	{pos =  { 0.5,  0.5,  0.0}, color = {1.0, 0.0, 0.0}},
	{pos =  {-0.5,  0.5,  0.0}, color = {1.0, 0.0, 0.0}},
}

create_graphics_pipeline :: proc(using state: ^VulkanState) -> bool {

/*
GraphicsPipelineCreateInfo :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	flags:               PipelineCreateFlags,
	stageCount:          u32,
	pStages:             [^]PipelineShaderStageCreateInfo,
	pVertexInputState:   ^PipelineVertexInputStateCreateInfo,
	pInputAssemblyState: ^PipelineInputAssemblyStateCreateInfo,
	pTessellationState:  ^PipelineTessellationStateCreateInfo,
	pViewportState:      ^PipelineViewportStateCreateInfo,
	pRasterizationState: ^PipelineRasterizationStateCreateInfo,
	pMultisampleState:   ^PipelineMultisampleStateCreateInfo,
	pDepthStencilState:  ^PipelineDepthStencilStateCreateInfo,
	pColorBlendState:    ^PipelineColorBlendStateCreateInfo,
	pDynamicState:       ^PipelineDynamicStateCreateInfo,
	layout:              PipelineLayout,
	renderPass:          RenderPass,
	subpass:             u32,
	basePipelineHandle:  Pipeline,
	basePipelineIndex:   i32,
}
*/

	stages := [Shader]vk.PipelineShaderStageCreateInfo{}
	for shader in Shader {
		stages[shader] = vk.PipelineShaderStageCreateInfo{
			sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
			pName = "main",
			stage = {shaders[shader].stage},
			module = shaders[shader].module,
		}
	}

	vertex_binding_description := vk.VertexInputBindingDescription{
			binding = 0,
			stride = size_of(Vertex),
			inputRate = .VERTEX,	
	}

	vertex_attribute_descriptions := [2]vk.VertexInputAttributeDescription{
		0 =	{
			binding = 0,
			location = 0,
			format = .R32G32B32_SFLOAT,
			offset = 0,
		},
		1 = {
			binding = 0,
			location = 1,
			format = .R32G32B32_SFLOAT,
			offset = size_of(linalg.Vector3f32)
		}
	}

	vertex_input_state := vk.PipelineVertexInputStateCreateInfo{
		sType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
		vertexBindingDescriptionCount = 1,
		pVertexBindingDescriptions = &vertex_binding_description,
		vertexAttributeDescriptionCount = len(vertex_attribute_descriptions),
		pVertexAttributeDescriptions = raw_data(vertex_attribute_descriptions[:])
	}

	input_assembly_state := vk.PipelineInputAssemblyStateCreateInfo{
		sType = .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
		topology = .TRIANGLE_LIST,
		primitiveRestartEnable = false,
	}

	viewport_state := vk.PipelineViewportStateCreateInfo{
		sType = .PIPELINE_VIEWPORT_STATE_CREATE_INFO,
		viewportCount = 1,
		pViewports = &swapchain.viewport,
		scissorCount = 1,
		pScissors = &swapchain.scissor,
	}
	
	rast_state := vk.PipelineRasterizationStateCreateInfo{
		sType = .PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
		lineWidth = 1.0,
		cullMode = {.BACK},
		frontFace = .CLOCKWISE,
		polygonMode = .FILL,
	}

	color_blend_attachment := vk.PipelineColorBlendAttachmentState{
		blendEnable = true,
		colorWriteMask = { .R, .G, .B, .A},
		srcColorBlendFactor = .ONE,
		dstColorBlendFactor = .ZERO,
		colorBlendOp = .ADD,
		srcAlphaBlendFactor = .ONE,
		dstAlphaBlendFactor = .ZERO,
		alphaBlendOp = .ADD,
	}

	color_blend_state := vk.PipelineColorBlendStateCreateInfo{
		sType = .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
		attachmentCount = 1,
		pAttachments = &color_blend_attachment,
	}

	dynamic_states := []vk.DynamicState{.VIEWPORT, .SCISSOR}
	dynamic_state := vk.PipelineDynamicStateCreateInfo{
		sType = .PIPELINE_DYNAMIC_STATE_CREATE_INFO,
		pDynamicStates = raw_data(dynamic_states),
	}

	// TODO(Matt): look at descriptor sets and push constants
	layout_create_info := vk.PipelineLayoutCreateInfo{
		sType = .PIPELINE_LAYOUT_CREATE_INFO,
		setLayoutCount = 0,
		pSetLayouts = nil,
		pushConstantRangeCount = 0,
		pPushConstantRanges = nil,
	}

	check(vk.CreatePipelineLayout(device.handle, &layout_create_info, nil, &graphics_pipeline.layout)) or_return
	
    create_info := vk.GraphicsPipelineCreateInfo{
        sType = .GRAPHICS_PIPELINE_CREATE_INFO,
        stageCount = len(stages),
		layout = graphics_pipeline.layout,
		renderPass = render_pass.handle,
		subpass = 0,
		pStages = ([^]vk.PipelineShaderStageCreateInfo)(&stages),
        pVertexInputState = &vertex_input_state,
		pInputAssemblyState = &input_assembly_state,
		pTessellationState = nil,
		pViewportState = &viewport_state,
		pRasterizationState = &rast_state,
		pColorBlendState = &color_blend_state,
		pDynamicState = &dynamic_state,
    }

    check(vk.CreateGraphicsPipelines(device.handle, 0, 1, &create_info, nil, &graphics_pipeline.handle)) or_return
    return true
}

destroy_graphics_pipeline :: proc(device: ^VulkanDevice, graphics_pipeline: ^VulkanGraphicsPipeline) {
	vk.DestroyPipeline(device.handle, graphics_pipeline.handle, nil)
	vk.DestroyPipelineLayout(device.handle, graphics_pipeline.layout, nil)
}
