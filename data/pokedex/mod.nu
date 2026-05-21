# Pokedex — query pokemon data from the shell

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

# Full entry for a pokemon by name or id
export def show [
    query: string # Pokemon name or id
    --moves (-m) # show moves as well
] {
    let res = find-pokemon $query
    if $moves {
        $res
    } else {
        $res | reject moves
    }
}

# Base stats for a pokemon
export def stats [
    query: string # Pokemon name or id
] {
    let pokemon = (find-pokemon $query)
    let total = ($pokemon.stats | values | math sum)
    { name: $pokemon.name, id: $pokemon.id }
    | merge $pokemon.stats
    | insert total $total
}

# Moves grouped by learn method
export def moves [
    query: string # Pokemon name or id
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
    ...names: string # Two or more pokemon names or ids
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
