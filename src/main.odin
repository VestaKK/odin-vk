
package main

import "core:fmt"
import "core:log"
import "core:os"
import "core:mem"
import "vendor:glfw"
import "renderer"
import "platform"

Width :: 640
Height :: 480

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.printf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.printf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.printf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.printf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}
   
    // TODO(chowie): Ideally this should be wrapped in with creating a
    // Win32 window! Windows should serve the graphics, not graphics
    // serve the window (that's stupid)!
    if !glfw.Init() {
        os.exit(1)
    }
    defer glfw.Terminate()

    glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
    window := glfw.CreateWindow(Width, Height, "A Working Window", nil, nil)
    defer glfw.WindowCloseProc(window)

    //
    // Renderer
    //

    vks: renderer.VulkanState
    ok := renderer.init_vulkan(&vks, window, Width, Height)
    if !ok {
        fmt.printf("Could not initialise vulkan state")
        os.exit(1)
    }
    defer renderer.shutdown(&vks)

    //
    // GLFW
    //

    // TODO(chowie): Move this out into Win32
    glfw.MakeContextCurrent(window)
    glfw.SetWindowUserPointer(window, &vks)

    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()
    }
}
