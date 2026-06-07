package main

import "core:fmt"
import "core:time"
import "core:math"
import "core:math/rand"
import "core:math/linalg"

import img "core:image"
import img_png "core:image/png"

import myglfw "./glfw"

import gl "vendor:OpenGL"
import glfw "vendor:glfw"

COLOR_CLOSED :: [3]f32 { 0.36, 0.86, 0.68 }
COLOR_OPENED :: [3]f32 { 0.32, 0.32, 0.32 }
COLOR_FLAG   :: [3]f32 { 0.15, 0.15, 0.15 }
COLOR_DIGIT  :: [3]f32 { 0.90, 0.90, 0.90 }

LERP_SPEED_NEIGHBORS : f32 : 2
LERP_SPEED_INNER_CORNERS : f32 : 2
LERP_SPEED_UNCOVER : f32 : 2
LERP_SPEED_FLAG : f32 : 4

Shader_Vertex :: struct {
    pos : [3]f32,
}

Shader_Index :: u32

Shader_Instance :: struct {
    model : matrix[4, 4]f32,

    lerps : [Shader_Instance_Lerp]f32,

    opened : u32,
    digit : u32,
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
    Flag,
}

Tile :: struct {
    opened : bool,
    mine   : bool,
    flag   : bool,
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
            present[tn] = false
        }
        else {
            present[tn] = (nn.opened == n.opened) && (nn.flag == n.flag)
        }
    }

    s : f32 = LERP_SPEED_NEIGHBORS
    v : f32 = LERP_SPEED_INNER_CORNERS

    newLerpDeltas[.NW] = (!present[.WW] && !present[.NN]) ? s : -s
    newLerpDeltas[.NE] = (!present[.NN] && !present[.EE]) ? s : -s
    newLerpDeltas[.SE] = (!present[.EE] && !present[.SS]) ? s : -s
    newLerpDeltas[.SW] = (!present[.SS] && !present[.WW]) ? s : -s

    newLerpDeltas[.NN] = !present[.NN] ? s : -s
    newLerpDeltas[.EE] = !present[.EE] ? s : -s
    newLerpDeltas[.SS] = !present[.SS] ? s : -s
    newLerpDeltas[.WW] = !present[.WW] ? s : -s

    newLerpDeltas[.NWI] = present[.WW] && present[.NN] && !present[.NW] ? v : -v
    newLerpDeltas[.NEI] = present[.NN] && present[.EE] && !present[.NE] ? v : -v
    newLerpDeltas[.SEI] = present[.EE] && present[.SS] && !present[.SE] ? v : -v
    newLerpDeltas[.SWI] = present[.SS] && present[.WW] && !present[.SW] ? v : -v

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
    if tile.mine {
        // TODO: initiate game over sequence
        return
    }

    tile.opened = true
    tile.flag = false

    s : f32 = LERP_SPEED_UNCOVER

    tile.lerpDeltas[.Transparency] = s
    tile.lerpDeltas[.Scale]        = s

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

minesweeper_flag :: proc(grid : Grid(Tile), instances : Grid(Shader_Instance), col, row : int) {
    tile, ok := grid_ref(grid, col, row)
    if !ok { return }

    if tile.opened { return }

    s : f32 = LERP_SPEED_FLAG

    tile.flag = !tile.flag
    tile.lerpDeltas[.Flag] = tile.flag ? s : -s
    updateLerps(grid, col, row)

    for tn in TileNeighbor {
        offset := neighborOffset(tn)
        updateLerps(grid, col + offset.x, row + offset.y)
    }
}

minesweeper_chord :: proc(grid : Grid(Tile), instances : Grid(Shader_Instance), col, row : int) {
    this, ok := grid_get(grid, col, row)
    if !ok { return }
    if !this.opened { return }

    unflaggedMines := 0
    flaggedMines := 0

    for tn in TileNeighbor {
        offset := neighborOffset(tn)
        n := grid_get(grid, col + offset.x, row + offset.y) or_continue

        if n.flag { flaggedMines += 1 }
        if !n.flag && n.mine { unflaggedMines += 1 }
    }

    // TODO: I've seen some people arguing that this should uncover all unflagged neighbors,
    // so that the player isn't incentivized to delegate flag counting to the game itself.
    // We might want to have this, but generally that's not how it works
    if flaggedMines != this.minesAround {
        return
    }

    if unflaggedMines > 0 {
        // TODO: initiate game over sequence
        return
    }

    for tn in TileNeighbor {
        offset := neighborOffset(tn)
        minesweeper_uncover(grid, instances, col + offset.x, row + offset.y)
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








    program_tile, _ := gl.load_shaders_file("shaders-built/tile-vert.glsl", "shaders-built/tile-frag.glsl")
    defer gl.DeleteProgram(program_tile)

    program_digit, _ := gl.load_shaders_file("shaders-built/digit-vert.glsl", "shaders-built/digit-frag.glsl")
    defer gl.DeleteProgram(program_digit)




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

            instance, _ := grid_ref(instances, x, y)
            instance.digit = cast(u32)mines
        }
    }


    // TODO: we might want to have a small queue of inputs but i have no clue rn (and dont really care)
    // alternatively we can handle the click in the event handler itself, but ehhhhhhh maybe
    WindowData :: struct {
        click_present : bool,
        click_pos : [2]f32,
        click_uncover : bool,

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
        wdata.click_uncover = button == .Left
    })

    glfw.SetScrollCallback(window, proc "c" (window : glfw.WindowHandle, x, y : f64) {
        wdata := cast(^WindowData)glfw.GetWindowUserPointer(window)
        wdata.scrolls += { cast(f32)x, cast(f32)y }
    })



    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, buffer_instances)
    gl.NamedBufferData(buffer_instances, size_of(Shader_Instance) * len(instances.vals), raw_data(instances.vals), gl.STATIC_DRAW)


    fmt.println(align_of(Shader_Instance), size_of(Shader_Instance))





    tex_tiles : u32

    gl.GenTextures(1, &tex_tiles);
    gl.BindTexture(gl.TEXTURE_2D, tex_tiles);

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    img_tiles, _ := img.load_from_file("tiles.png")

    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, cast(i32)img_tiles.width, cast(i32)img_tiles.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, raw_data(img_tiles.pixels.buf));
    gl.GenerateMipmap(gl.TEXTURE_2D);











    
    position : [3]f32 = { 0, 0, 5 }
    direction : [3]f32 = { 0, 0, -5 }

    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

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

        position += { 0, 0, -1 } * wdata.scrolls.y * 0.1

        // TODO: it might be useful to change zoom limits depending on screen aspect ratio or smth
        max_zoom_in  :: 1
        max_zoom_out :: 100
        position.z = math.clamp(position.z, max_zoom_in, max_zoom_out)

        wdata.scrolls = {}







        // NOTE: this is completely unnecessary, but it doesn't matter at all
        matrix_view  := linalg.matrix4_scale_f32({ 1, 1, 1 } / position.z) * linalg.matrix4_look_at_f32(position, position + direction, { 0.0, 1.0, 0.0 })
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

            tile, ok := grid_get(ms_grid, col, row)
            if ok {
                if wdata.click_uncover && tile.opened {
                    minesweeper_chord(ms_grid, instances, col, row)
                }
                else if wdata.click_uncover {
                    minesweeper_uncover(ms_grid, instances, col, row)
                }
                else {
                    // TODO: flag
                    minesweeper_flag(ms_grid, instances, col, row)
                }
            }
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

        gl.ClearColor(COLOR_OPENED.x, COLOR_OPENED.y, COLOR_OPENED.z, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)



        gl.UseProgram(program_tile)

        gl.Uniform1f(0, time_passed)
        gl.UniformMatrix4fv(1, 1, gl.FALSE, cast(^f32)&matrix_view)
        gl.UniformMatrix4fv(2, 1, gl.FALSE, cast(^f32)&matrix_proj)

        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, tex_tiles)
        gl.Uniform1i(3, gl.TEXTURE0)

        gl.Uniform1f(4, 0.45)
        gl.Uniform1f(5, 0.05)

        gl.Uniform3f(6, COLOR_CLOSED.x, COLOR_CLOSED.y, COLOR_CLOSED.z)
        gl.Uniform3f(7, COLOR_OPENED.x, COLOR_OPENED.y, COLOR_OPENED.z) // NOTE: not actually used in shaders
        gl.Uniform3f(8, COLOR_FLAG.x,   COLOR_FLAG.y,   COLOR_FLAG.z)
        gl.Uniform3f(9, COLOR_DIGIT.x,  COLOR_DIGIT.y,  COLOR_DIGIT.z)



        gl.BindVertexArray(array_vertex)
        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, buffer_instances)
        gl.DrawElementsInstanced(gl.TRIANGLES, cast(i32)len(indexes), gl.UNSIGNED_INT, nil, cast(i32)len(instances.vals))




        gl.UseProgram(program_digit)

        gl.Uniform1f(0, time_passed)
        gl.UniformMatrix4fv(1, 1, gl.FALSE, cast(^f32)&matrix_view)
        gl.UniformMatrix4fv(2, 1, gl.FALSE, cast(^f32)&matrix_proj)

        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, tex_tiles)
        gl.Uniform1i(3, gl.TEXTURE0)

        gl.Uniform3f(6, COLOR_CLOSED.x, COLOR_CLOSED.y, COLOR_CLOSED.z)
        gl.Uniform3f(7, COLOR_OPENED.x, COLOR_OPENED.y, COLOR_OPENED.z) // NOTE: not actually used in shaders
        gl.Uniform3f(8, COLOR_FLAG.x,   COLOR_FLAG.y,   COLOR_FLAG.z)
        gl.Uniform3f(9, COLOR_DIGIT.x,  COLOR_DIGIT.y,  COLOR_DIGIT.z)

        gl.BindVertexArray(array_vertex)
        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, buffer_instances)
        gl.DrawElementsInstanced(gl.TRIANGLES, cast(i32)len(indexes), gl.UNSIGNED_INT, nil, cast(i32)len(instances.vals))




        glfw.SwapBuffers(window)
    }
}
