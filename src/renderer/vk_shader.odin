package renderer

import vk "vendor:vulkan"
import win32 "core:sys/windows"
import "core:fmt"
import "core:strings"
import "core:os"

VulkanShader :: struct {
    module: vk.ShaderModule,
}

Shader :: enum {
    Vert,
    Frag,
}

VulkanShaderStore :: struct {
    shaders: [len(Shader)]VulkanShader
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

    check(vk.CreateShaderModule(device.logical, &frag_create_info, nil, &shader_store.shaders[Shader.Frag].module)) or_return
    check(vk.CreateShaderModule(device.logical, &vert_create_info, nil, &shader_store.shaders[Shader.Vert].module)) or_return

    return true
}

destroy_shaders :: proc(device: ^VulkanDevice, shader_store: ^VulkanShaderStore) {
    for shader in shader_store.shaders {
        vk.DestroyShaderModule(device.logical, shader.module, nil)
    }
}