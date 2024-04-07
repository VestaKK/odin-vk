package renderer

import vk "vendor:vulkan"
import win32 "core:sys/windows"
import "core:fmt"
import "core:strings"
import "core:os"

VulkanShader :: struct {
    module: vk.ShaderModule,
}

VulkanShaderStore :: struct #raw_union {
    using _: struct {
        vert: VulkanShader,
        frag: VulkanShader,
    },
    all: [2]VulkanShader,
}

create_shaders :: proc(using state: ^VulkanState) -> bool {

    frag_file, _ := os.read_entire_file("res/shaders/spv/frag.spv")
    vert_file, _ := os.read_entire_file("res/shaders/spv/vert.spv")
    defer delete(frag_file) 
    defer delete(vert_file)

    frag_create_info := vk.ShaderModuleCreateInfo {
        sType = .SHADER_MODULE_CREATE_INFO,
        codeSize = len(frag_file) * size_of(u8),
        pCode = cast(^u32)raw_data(frag_file),
    } 

    vert_create_info := vk.ShaderModuleCreateInfo {
        sType = .SHADER_MODULE_CREATE_INFO,
        codeSize = len(vert_file) * size_of(u8),
        pCode = cast(^u32)raw_data(vert_file),
    }

    check(vk.CreateShaderModule(device.logical, &frag_create_info, nil, &shaders.frag.module)) or_return
    check(vk.CreateShaderModule(device.logical, &vert_create_info, nil, &shaders.vert.module)) or_return

    return true
}

destroy_shaders :: proc(device: ^VulkanDevice, shaders: ^VulkanShaderStore) {
    for shader in shaders.all {
        vk.DestroyShaderModule(device.logical, shader.module, nil)
    }
}