package main

import "core:fmt"
import "core:math/linalg"

import gl "vendor:OpenGL"
import glfw "vendor:glfw"

Shader_Vertex :: struct {
    pos : [3]f32,
}

Shader_Index :: u32

Shader_Instance :: struct {
    model : matrix[4, 4]f32,
    col : [4]f32,
    a : [4]f32,
}

Tile :: struct {
    opened : bool,
}

Grid :: struct($ty : typeid) {
    cols : int,
    rows : int,
    vals : []ty,
}

grid_make :: proc($ty : typeid, cols, rows : int) -> Grid(ty) {
    return {
        rows, cols, make([]ty, rows * cols)
    }
}

grid_get :: proc(grid : Grid($ty), col, row : int) -> (val : ty, ok : bool = false) {
    if row < 0 || col < 0 { return }
    if row >= grid.rows || col >= grid.cols { return }

    return grid.vals[row * grid.cols + col], true
}

grid_set :: proc(grid : Grid($ty), col, row : int, val : ty) -> (ok : bool = false) {
    if row < 0 || col < 0 { return }
    if row >= grid.rows || col >= grid.cols { return }

    grid.vals[row * grid.cols + col] = val
    return true
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



    buffer_instances : u32
    gl.GenBuffers(1, &buffer_instances)
    defer gl.DeleteBuffers(1, &buffer_instances)



    ms_grid := grid_make(Tile, 3, 3)
    instances := grid_make(Shader_Instance, 3, 3)

    grid_set(ms_grid, 1, 1, Tile{ true })

    for y in 0..<ms_grid.rows {
        for x in 0..<ms_grid.cols {
            ms, _ := grid_get(ms_grid, x, y)
            instance : Shader_Instance = {
                model = linalg.matrix4_translate_f32({ 0.0 + cast(f32)x, 0.0 + cast(f32)y, 0.0 }),
                col = ms.opened ? { 1, 1, 1, 1 } : { 0, 0, 0, 1 }
            }

            grid_set(instances, x, y, instance)
        }
    }



    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, buffer_instances)
    gl.NamedBufferData(buffer_instances, size_of(Shader_Instance) * len(instances.vals), raw_data(instances.vals), gl.STATIC_DRAW)


    fmt.println(align_of(Shader_Instance), size_of(Shader_Instance))



    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()

        gl.Viewport(0, 0, 800, 600)

        gl.ClearColor(0.1, 0.2, 0.4, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)



        gl.UseProgram(program)


        // NOTE: this is completely unnecessary, but it doesn't matter at all
        matrix_view  := linalg.matrix4_look_at_f32({ 0.0, 0.0, 5.0 }, { 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 })
        matrix_proj := linalg.matrix_ortho3d_f32(-4, 4, -3, 3, 0.1, 100)

        gl.Uniform1f(0, 0)
        gl.UniformMatrix4fv(2, 1, gl.FALSE, cast(^f32)&matrix_view)
        gl.UniformMatrix4fv(3, 1, gl.FALSE, cast(^f32)&matrix_proj)



        gl.BindVertexArray(array_vertex)
        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, buffer_instances)
        gl.DrawElementsInstanced(gl.TRIANGLES, cast(i32)len(indexes), gl.UNSIGNED_INT, nil, cast(i32)len(instances.vals))




        glfw.SwapBuffers(window)
    }
}
