# Pokedex — query pokemon data from the shell

use completion.nu *

const DATA_DIR = path self .

def load [] {
    let yaml_path = ($DATA_DIR | path join "pokedex.yaml")
    let nuon_path = ($DATA_DIR | path join "pokedex.nuon")

    if ($nuon_path | path exists) {
        let yaml_mtime = (ls $yaml_path | get 0.modified)
        let nuon_mtime = (ls $nuon_path | get 0.modified)
        if $nuon_mtime >= $yaml_mtime {
            return (open $nuon_path)
        }
    }

    print "Building pokedex cache..."
    let data = (open $yaml_path)
    $data | save -f $nuon_path
    $data
}

def find-pokemon [query: string] {
    let data = (load)
    let id = (try { $query | into int } catch { null })
    let matches = if $id != null {
        $data | where id == $id
    } else {
        $data | where name == ($query | str downcase)
    }
    if ($matches | is-empty) {
        error make { msg: $"Pokemon '($query)' not found" }
    }
    $matches | first
}

# List all pokemon
export def main [] {
    load | select id name types
}

# Open a pokemon's pokemondb page in Firefox
export def wiki [
    query: string@"nu-complete pokemon" # Pokemon name
] {
    let _ = firefox $"https://pokemondb.net/pokedex/($query)" | complete
}

# Full entry for a pokemon by name or id
export def show [
    query: string@"nu-complete pokemon" # Pokemon name or id
    --moves (-m) # show moves as well
] {
    let res = find-pokemon $query
    let res = $res
        | insert effectiveness (defense-effectiveness-chart ...$res.types)
        | update evolution (chain-paths $res.evolution)
    if $moves {
        $res
    } else {
        $res | reject moves
    }
}

def chain-paths [node, prefix: string = ""] {
    let label = if $prefix == "" { $node.name } else { $"($prefix) → ($node.name)" }
    if ($node.evolves_to | is-empty) {
        [$label]
    } else {
        $node.evolves_to | each {|c| chain-paths $c $label} | flatten
    }
}

def types [] {
  [
    normal
    fire
    water
    electric
    grass
    ice
    fighting
    poison
    ground
    flying
    psychic
    bug
    rock
    ghost
    dragon
    dark
    steel
    fairy
  ]
}

export def effectiveness [attacker: string, ...defender: string] {
    if ($defender | length) == 0 {
        effectiveness-pokemon $attacker
    } else {
        effectiveness-types $attacker ...$defender
    }
}

def effectiveness-types [attacker: string, ...defender: string] {
    let yaml_path = ($DATA_DIR | path join type-effectiveness.yaml)
    let v = $defender | each {|d| (open $yaml_path | get $attacker | get $d)} | math product | into float
    colorize-effectiveness $v
}

def effectiveness-pokemon [pkmn: string] {
    let pokemon = (find-pokemon $pkmn)
    types
        | each {|t| {$t: (effectiveness $t ...$pokemon.types)}}
        | reduce {|it, acc| $acc | merge $it}
}

def colorize-effectiveness [val: float] {
    match $val {
        0.25 => $"(ansi black)(ansi bg_red)1/4(ansi reset)",
        0.5  => $"(ansi black)(ansi bg_yellow)1/2(ansi reset)",
        2.0  => $"(ansi black)(ansi bg_green) 2 (ansi reset)",
        4.0  => $"(ansi black)(ansi bg_cyan) 4 (ansi reset)",
        _    => $" ($val | into string) "
    }
}

export def defense-effectiveness-chart [...pokemon_types: string] {
    types
        | each {|t| {$t: (effectiveness $t ...$pokemon_types)}}
        | reduce {|it, acc| $acc | merge $it}
}

# Base stats for a pokemon
export def stats [
    query: string@"nu-complete pokemon" # Pokemon name or id
] {
    let pokemon = (find-pokemon $query)
    let total = ($pokemon.stats | values | math sum)
    { name: $pokemon.name, id: $pokemon.id }
    | merge $pokemon.stats
    | insert total $total
    | reject id
    | insert effectiveness (defense-effectiveness-chart ...$pokemon.types)
}

# Moves grouped by learn method
export def moves [
    query: string@"nu-complete pokemon" # Pokemon name or id
] {
    let pokemon = (find-pokemon $query)
    $pokemon.moves | transpose method moves
}

# All pokemon of a given type
export def type [
    type_name: string # Type name (e.g. fire, water)
] {
    let q = ($type_name | str downcase)
    load | where { |p| $q in $p.types } | select id name types
}

# All pokemon with a given ability
export def ability [
    ability_name: string # Ability name
] {
    let q = ($ability_name | str downcase)
    load | where { |p| $p.abilities | any { |a| $a.name == $q } } | select id name abilities
}

# Search pokemon by name substring
export def search [
    query: string # Search string
] {
    let q = ($query | str downcase)
    load | where { |p| $p.name | str contains $q } | select id name types
}

# Side-by-side stat comparison
export def compare [
    ...names: string@"nu-complete pokemon" # Two or more pokemon names or ids
] {
    if ($names | length) < 2 {
        error make { msg: "Provide at least 2 pokemon to compare" }
    }
    let pokemon = ($names | each { |n| find-pokemon $n })
    [hp attack defense special-attack special-defense speed total] | each { |s|
        mut row = { stat: $s }
        for p in $pokemon {
            let val = if $s == "total" {
                $p.stats | values | math sum
            } else {
                $p.stats | get $s
            }
            $row = ($row | insert $p.name $val)
        }
        $row
    }
}

# Random pokemon entry
export def random [] {
    load | shuffle | first
}

def colorize-matrix [val: float] {
    match $val {
        0.0  => $"(ansi white)(ansi bg_dark_gray) 0 (ansi reset)",
        0.25 => $"(ansi black)(ansi bg_red)1/4(ansi reset)",
        0.5  => $"(ansi black)(ansi bg_red)1/2(ansi reset)",
        2.0  => $"(ansi black)(ansi bg_green) 2 (ansi reset)",
        4.0  => $"(ansi black)(ansi bg_green) 4 (ansi reset)",
        _    => " 1 "
    }
}

# Type effectiveness chart (attack rows × defense columns)
export def effectiveness-chart [--numerical] {
    let yaml_path = ($DATA_DIR | path join type-effectiveness.yaml)
    let data = (open $yaml_path)
    let type_list = (types)

    $type_list | each {|attacker|
        let cells = $type_list | reduce -f {} {|defender, acc|
            let v = ($data | get $attacker | get $defender | into float)
            let key = ($defender | str substring 0..<3 | str upcase)
            let val = if $numerical { $v } else { colorize-matrix $v }
            $acc | insert $key $val
        }
        {"ATK\\DEF": ($attacker | str upcase)} | merge $cells
    }
}
