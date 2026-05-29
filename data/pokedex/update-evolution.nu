#!/usr/bin/env nu

# One-off script: fetch evolution chains from PokeAPI and embed them in pokedex.yaml.

const DATA_DIR = path self .

def simplify-chain [node] {
    {
        name: $node.species.name,
        evolves_to: ($node.evolves_to | each {|c| simplify-chain $c})
    }
}

def chain-species [node] {
    [$node.name] | append ($node.evolves_to | each {|c| chain-species $c} | flatten)
}

print "Fetching evolution chains..."
let chains = (1..600 | par-each --threads 16 {|id|
    try {
        let resp = (http get $"https://pokeapi.co/api/v2/evolution-chain/($id)/")
        simplify-chain $resp.chain
    } catch { null }
} | compact)

print $"Fetched ($chains | length) chains"

let species_to_chain = ($chains | reduce -f {} {|c, acc|
    chain-species $c | reduce -f $acc {|s, a| $a | upsert $s $c }
})

let yaml_path = ($DATA_DIR | path join pokedex.yaml)
let nuon_path = ($DATA_DIR | path join pokedex.nuon)

print "Loading pokedex..."
let pokedex = (open $yaml_path)

let updated = ($pokedex | each {|p|
    let name = $p.name
    let base = ($name | split row '-' | first)
    let chain = if ($name in $species_to_chain) {
        $species_to_chain | get $name
    } else if ($base in $species_to_chain) {
        $species_to_chain | get $base
    } else {
        null
    }
    if $chain != null { $p | insert evolution $chain } else { $p }
})

let missing = ($updated | where {|p| 'evolution' not-in ($p | columns)} | get name)
print $"Missing evolution for ($missing | length) pokemon"
if ($missing | length) > 0 and ($missing | length) <= 30 {
    print $missing
}

print "Saving pokedex.yaml..."
$updated | save -f $yaml_path
if ($nuon_path | path exists) { rm $nuon_path }
print "Done"
