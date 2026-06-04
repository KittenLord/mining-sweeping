package main

import "core:fmt"
import "core:math/linalg"

import gl "vendor:OpenGL"
import glfw "vendor:glfw"

Shader_Vertex :: struct {
    pos : [3]f32,
}

Shader_Index :: u32

mkGrid :: proc($ty : typeid, row, col : int) -> (result : [][]ty) {
    result = make([][]ty, row)
    for &v, i in result {
        v = make([]ty, col)
    }

    return
}

main :: proc () {
    fmt.println("Hello, World!");

    glfw.Init()
    defer glfw.Terminate()

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint_bool(glfw.RESIZABLE, false)

    window := glfw.CreateWindow(800, 600, "mine sweep er", nil, nil)
    defer glfw.DestroyWindow(window)

    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)

    gl.load_up_to(4, 6, proc (p : rawptr, name : cstring) {
        (cast(^rawptr)p)^ = glfw.GetProcAddress(name)
    })








    program, _ := gl.load_shaders_file("shaders/vertex.glsl", "shaders/fragment.glsl")
    defer gl.DeleteProgram(program)




    array_vertex : u32
    gl.GenVertexArrays(1, &array_vertex)
    defer gl.DeleteVertexArrays(1, &array_vertex)
    gl.BindVertexArray(array_vertex)




    buffer_vertex : u32
    gl.GenBuffers(1, &buffer_vertex)
    defer gl.DeleteBuffers(1, &buffer_vertex)
    gl.BindBuffer(gl.ARRAY_BUFFER, buffer_vertex)

    vertexes : []Shader_Vertex = {
        {
            pos = { -0.5, -0.5, 0.0 },
        },
        {
            pos = { -0.5,  0.5, 0.0 },
        },
        {
            pos = {  0.5,  0.5, 0.0 },
        },
        {
            pos = {  0.5, -0.5, 0.0 },
        },
    }
    gl.NamedBufferData(buffer_vertex, size_of(Shader_Vertex) * len(vertexes), raw_data(vertexes), gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Shader_Vertex), offset_of(Shader_Vertex, pos))



    buffer_index : u32
    gl.GenBuffers(1, &buffer_index)
    defer gl.DeleteBuffers(1, &buffer_index)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, buffer_index)

    indexes : []Shader_Index = {
        0, 1, 2, 2, 3, 0
    }
    gl.NamedBufferData(buffer_index, size_of(Shader_Index) * len(indexes), raw_data(indexes), gl.STATIC_DRAW)




    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()

        gl.Viewport(0, 0, 800, 600)

        gl.ClearColor(0.1, 0.2, 0.4, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)



        gl.UseProgram(program)


        // NOTE: this is completely unnecessary, but it doesn't matter at all

        // matrix_model := linalg.matrix4_translate_f32({ 0.0, 0.0, 1.0 } * math.sin(time_passed)) * linalg.matrix4_rotate_f32(time_passed, { 1.0, 1.0, 1.0 })
        matrix_model := linalg.MATRIX4F32_IDENTITY
        matrix_view  := linalg.matrix4_look_at_f32({ 0.0, 0.0, 5.0 }, { 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 })
        matrix_proj := linalg.matrix_ortho3d_f32(-4, 4, -3, 3, 0.1, 100)

        gl.Uniform1f(0, 0)
        gl.UniformMatrix4fv(1, 1, gl.FALSE, cast(^f32)&matrix_model)
        gl.UniformMatrix4fv(2, 1, gl.FALSE, cast(^f32)&matrix_view)
        gl.UniformMatrix4fv(3, 1, gl.FALSE, cast(^f32)&matrix_proj)



        gl.BindVertexArray(array_vertex)
        gl.DrawElements(gl.TRIANGLES, cast(i32)len(indexes), gl.UNSIGNED_INT, nil)




        glfw.SwapBuffers(window)
    }
}

