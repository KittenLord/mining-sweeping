package main

import "core:fmt"
import "core:time"
import "core:math"
import "core:math/rand"
import "core:math/linalg"

import myglfw "./glfw"

import gl "vendor:OpenGL"
import glfw "vendor:glfw"

Shader_Vertex :: struct {
    pos : [3]f32,
}

Shader_Index :: u32

Shader_Instance :: struct {
    model : matrix[4, 4]f32,

    lerps : [Shader_Instance_Lerp]f32,

    opened : u32,
    // digit : f32,
}

// TODO: i think we do an extra lerp for corners when they are inverted
Shader_Instance_Lerp :: enum {
    NW,
    NN,
    NE,
    EE,
    SE,
    SS,
    SW,
    WW,

    NWI,
    NEI,
    SWI,
    SEI,

    Transparency,
    Scale,
}

Tile :: struct {
    opened : bool,
    mine   : bool,
    minesAround : int,

    lerpDeltas : [Shader_Instance_Lerp]f32,
}

TileNeighbor :: enum {
    NW,
    NN,
    NE,
    EE,
    SE,
    SS,
    SW,
    WW,
}

neighborOffset :: proc(n : TileNeighbor) -> [2]int {
    switch n {
    case .NW: return { -1, -1 }
    case .NN: return {  0, -1 }
    case .NE: return {  1, -1 }
    case .EE: return {  1,  0 }
    case .SE: return {  1,  1 }
    case .SS: return {  0,  1 }
    case .SW: return { -1,  1 }
    case .WW: return { -1,  0 }
    case: panic("bad")
    }
}

mergeLerps :: proc(old, new : ^[Shader_Instance_Lerp]f32) {
    for &l, i in old {
        if new[i] == 0 { continue }
        l = new[i]
    }
}

updateLerps :: proc(grid : Grid(Tile), col, row : int) {
    n, ok := grid_get(grid, col, row)
    if !ok { return }

    newLerpDeltas : [Shader_Instance_Lerp]f32

    present : [TileNeighbor]bool
    for tn in TileNeighbor {
        offset := neighborOffset(tn)
        nn, ok := grid_get(grid, col + offset.x, row + offset.y)

        opened : bool

        if !ok {
            opened = true
        }
        else {
            opened = nn.opened
        }

        present[tn] = !opened
    }

    newLerpDeltas[.NW] = (!present[.WW] && !present[.NN]) ? 1 : -1
    newLerpDeltas[.NE] = (!present[.NN] && !present[.EE]) ? 1 : -1
    newLerpDeltas[.SE] = (!present[.EE] && !present[.SS]) ? 1 : -1
    newLerpDeltas[.SW] = (!present[.SS] && !present[.WW]) ? 1 : -1

    newLerpDeltas[.NN] = !present[.NN] ? 1 : -1
    newLerpDeltas[.EE] = !present[.EE] ? 1 : -1
    newLerpDeltas[.SS] = !present[.SS] ? 1 : -1
    newLerpDeltas[.WW] = !present[.WW] ? 1 : -1

    newLerpDeltas[.NWI] = present[.WW] && present[.NN] && !present[.NW] ? 1 : -1
    newLerpDeltas[.NEI] = present[.NN] && present[.EE] && !present[.NE] ? 1 : -1
    newLerpDeltas[.SEI] = present[.EE] && present[.SS] && !present[.SE] ? 1 : -1
    newLerpDeltas[.SWI] = present[.SS] && present[.WW] && !present[.SW] ? 1 : -1

    mergeLerps(&n.lerpDeltas, &newLerpDeltas)
    grid_set(grid, col, row, n)
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

grid_ref :: proc(grid : Grid($ty), col, row : int) -> (ref : ^ty, ok : bool = false) {
    if row < 0 || col < 0 { return }
    if row >= grid.rows || col >= grid.cols { return }

    return &grid.vals[row * grid.cols + col], true
}

minesweeper_uncover :: proc(grid : Grid(Tile), instances : Grid(Shader_Instance), col, row : int) {
    tile, ok := grid_ref(grid, col, row)
    if !ok { return }

    if tile.opened { return }
    tile.opened = true

    tile.lerpDeltas[.Transparency] = 1
    tile.lerpDeltas[.Scale]        = 1

    instance, _ := grid_ref(instances, col, row)
    instance.opened = 1

    for tn in TileNeighbor {
        offset := neighborOffset(tn)

        if tile.minesAround == 0 {
            minesweeper_uncover(grid, instances, col + offset.x, row + offset.y)
        }
        else {
            updateLerps(grid, col + offset.x, row + offset.y)
        }
    }
}

ilerp :: proc(a, b, v : f32) -> f32 {
    return (v - a) / (b - a)
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








    program, _ := gl.load_shaders_file("shaders-built/tile-vert.glsl", "shaders-built/tile-frag.glsl")
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



    ms_grid := grid_make(Tile, 100, 100)
    instances := grid_make(Shader_Instance, 100, 100)

    for y in 0..<ms_grid.rows {
        for x in 0..<ms_grid.cols {
            ms, _ := grid_get(ms_grid, x, y)

            ms.mine = rand.float32() < 0.15

            instance : Shader_Instance = {
                model = linalg.matrix4_translate_f32({ 0.0 + cast(f32)x, 0.0 + cast(f32)y, 0.0 }),
                opened = ms.opened ? 1 : 0,
            }

            grid_set(ms_grid, x, y, ms)
            grid_set(instances, x, y, instance)
        }
    }

    for y in 0..<ms_grid.rows {
        for x in 0..<ms_grid.cols {
            mines := 0
            for tn in TileNeighbor {
                offset := neighborOffset(tn)
                n, ok := grid_get(ms_grid, x + offset.x, y + offset.y)

                if ok && n.mine {
                    mines += 1
                }
            }

            m, _ := grid_ref(ms_grid, x, y)
            m.minesAround = mines

            // fmt.println(mines)
        }
    }


    // TODO: we might want to have a small queue of inputs but i have no clue rn (and dont really care)
    // alternatively we can handle the click in the event handler itself, but ehhhhhhh maybe
    WindowData :: struct {
        click_present : bool,
        click_pos : [2]f32,
        scrolls : [2]f32,
    }

    wdata : WindowData = {
        click_present = false,
    }

    glfw.SetWindowUserPointer(window, &wdata)

    myglfw.SetMouseButtonCallback(window, proc "c" (window : glfw.WindowHandle, button : myglfw.MouseButton, action : myglfw.Action, mods : myglfw.Mods) {
        wdata := cast(^WindowData)glfw.GetWindowUserPointer(window)

        if action != .Press { return }

        wdata.click_present = true
        wdata.click_pos = myglfw.GetCursorPosf32(window)
    })

    glfw.SetScrollCallback(window, proc "c" (window : glfw.WindowHandle, x, y : f64) {
        wdata := cast(^WindowData)glfw.GetWindowUserPointer(window)
        wdata.scrolls += { cast(f32)x, cast(f32)y }
    })



    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, buffer_instances)
    gl.NamedBufferData(buffer_instances, size_of(Shader_Instance) * len(instances.vals), raw_data(instances.vals), gl.STATIC_DRAW)


    fmt.println(align_of(Shader_Instance), size_of(Shader_Instance))

    
    position : [3]f32 = { 0, 0, 5 }
    direction : [3]f32 = { 0, 0, -5 }


    time_start := time.now()
    time_last := time.now()

    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()

        time_now := time.now()
        time_passed := cast(f32)time.duration_seconds(time.diff(time_start, time_now))
        time_delta := cast(f32)time.duration_seconds(time.diff(time_last, time_now))
        defer time_last = time_now

        screen := myglfw.GetWindowSize(window)




        moveSpeed : f32 = 10

        position += { 0,  1, 0 } * myglfw.IsKeyPressed_f32(window, .LetterW) * time_delta * moveSpeed
        position += { 0, -1, 0 } * myglfw.IsKeyPressed_f32(window, .LetterS) * time_delta * moveSpeed

        position += { -1, 0, 0 } * myglfw.IsKeyPressed_f32(window, .LetterA) * time_delta * moveSpeed
        position += {  1, 0, 0 } * myglfw.IsKeyPressed_f32(window, .LetterD) * time_delta * moveSpeed

        position += { 0, 0, -1 } * wdata.scrolls.y * 0.2
        wdata.scrolls = {}







        // NOTE: this is completely unnecessary, but it doesn't matter at all
        matrix_view  := linalg.matrix4_scale_f32({ 1 / position.z, 1 / position.z, 1 / position.z }) * linalg.matrix4_look_at_f32(position, position + direction, { 0.0, 1.0, 0.0 })
        matrix_proj  := linalg.matrix_ortho3d_f32(-4, 4, -3, 3, 0.1, 100)

        if wdata.click_present {
            wdata.click_present = false

            v := wdata.click_pos
            pos4 := linalg.matrix4_inverse(matrix_view) * [4]f32{ ilerp(0, screen.x, v.x) * 8 - 4, -(ilerp(0, screen.y, v.y) * 6 - 3), 0, 1 }
            pos := pos4.xy / pos4.w
            pos.y = pos.y

            fmt.println(v)
            fmt.println(pos)

            col := cast(int)math.round(pos.x)
            row := cast(int)math.round(pos.y)

            minesweeper_uncover(ms_grid, instances, col, row)
        }




        for y in 0..<ms_grid.rows {
            for x in 0..<ms_grid.cols {
                ms, _ := grid_get(ms_grid, x, y)
                instance, _ := grid_get(instances, x, y)

                if ms.lerpDeltas == {} { continue }

                lerpsOld := instance.lerps
                for l, i in ms.lerpDeltas {
                    instance.lerps[i] = math.clamp(instance.lerps[i] + (l * time_delta), 0, 1)
                }

                if lerpsOld == instance.lerps {
                    ms.lerpDeltas = {}
                    continue
                }

                grid_set(instances, x, y, instance)
            }
        }
        gl.NamedBufferData(buffer_instances, size_of(Shader_Instance) * len(instances.vals), raw_data(instances.vals), gl.STATIC_DRAW)

        gl.Viewport(0, 0, cast(i32)screen.x, cast(i32)screen.y)

        gl.ClearColor(0.9, 0.9, 0.9, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)



        gl.UseProgram(program)

        gl.Uniform1f(0, time_passed)
        gl.UniformMatrix4fv(1, 1, gl.FALSE, cast(^f32)&matrix_view)
        gl.UniformMatrix4fv(2, 1, gl.FALSE, cast(^f32)&matrix_proj)
        gl.Uniform1f(3, 0.4)
        gl.Uniform1f(4, 0.1)



        gl.BindVertexArray(array_vertex)
        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, buffer_instances)
        gl.DrawElementsInstanced(gl.TRIANGLES, cast(i32)len(indexes), gl.UNSIGNED_INT, nil, cast(i32)len(instances.vals))




        glfw.SwapBuffers(window)
    }
}
