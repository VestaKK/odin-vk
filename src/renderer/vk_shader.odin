package renderer

import vk "vendor:vulkan"
import win32 "core:sys/windows"
import "core:fmt"
import "core:strings"
import "core:os"

VulkanShader :: struct {
    module: vk.ShaderModule,
    stage: vk.ShaderStageFlag,
}

Shader :: enum {
    Vert,
    Frag,
}


create_shader :: proc(
    device: vk.Device,
    shader_file_path: string
) -> (
    module: vk.ShaderModule, 
    ok: bool
) {
    shader_file, _ := os.read_entire_file(shader_file_path)
    defer delete(shader_file)
    create_info := vk.ShaderModuleCreateInfo {
        sType = .SHADER_MODULE_CREATE_INFO,
        codeSize = len(shader_file) * size_of(u8),
        pCode = cast(^u32)raw_data(shader_file),
    }
    check(vk.CreateShaderModule(device, &create_info, nil, &module)) or_return
    return module, true
}


create_shaders :: proc(using state: ^VulkanState) -> bool {
    shaders[.Frag].stage = .FRAGMENT
    shaders[.Frag].module = create_shader(device.handle, "res/shaders/spv/frag.spv") or_return    
    shaders[.Vert].stage = .VERTEX
    shaders[.Vert].module = create_shader(device.handle, "res/shaders/spv/vert.spv") or_return
    return true
}

destroy_shaders :: proc(device: ^VulkanDevice, shaders: ^[Shader]VulkanShader) {
    for &shader in shaders {
        vk.DestroyShaderModule(device.handle, shader.module, nil)
    }
}