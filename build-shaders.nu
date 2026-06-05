#!/bin/nu

# NOTE: used chatgpt for this because i dont know nu syntax too well :(

mkdir shaders-built

let include_tile = (open shaders/tile.glslh --raw)

ls shaders
| where type == file
| where name =~ '\.glsl$'
| each {|file|
    let content = (
        open $file.name --raw
        | str replace '#include "tile.glslh"' $include_tile
    )

    let out_path = (
        $file.name
        | path basename
        | $"shaders-built/($in)"
    )

    $content | save -f $out_path
}
