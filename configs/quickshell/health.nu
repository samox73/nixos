const temperature_offset = 0

def cpu-sample [] {
    let values = (
        open /proc/stat
        | lines
        | first
        | str trim
        | split row --regex '\s+'
        | skip 1
        | each { into int }
    )

    {
        idle: (($values | get 3) + ($values | get 4))
        total: ($values | math sum)
    }
}

def memory-percent [] {
    let values = (
        open /proc/meminfo
        | lines
        | parse --regex '^(?<key>\w+):\s+(?<value>\d+)'
    )
    let total = ($values | where key == "MemTotal" | get 0.value | into float)
    let available = ($values | where key == "MemAvailable" | get 0.value | into float)

    (((($total - $available) / $total) * 100) | math round)
}

def temperature-path [] {
    ls /sys/class/hwmon/*/name
    | get name
    | where { |path| (open $path | str trim) in ["coretemp" "k10temp"] }
    | get --optional 0
    | if $in == null { null } else {
        $in | path dirname | path join "temp1_input"
    }
}

def temperature [path] {
    if $path == null { null } else {
        (((open $path | into float) / 1000 + $temperature_offset) | math round)
    }
}

def report [previous, current, temp_path] {
    let total = $current.total - $previous.total
    let idle = $current.idle - $previous.idle
    let cpu = if $total == 0 { 0 } else {
        ((100 * (1 - $idle / $total)) | math round)
    }
    let disk = (sys disks | where mount == "/" | first)

    {
        cpu: $cpu
        memory: (memory-percent)
        temperature: (temperature $temp_path)
        disk: ((100 * (1 - $disk.free / $disk.total)) | math round)
    }
}

def main [--once] {
    let temp_path = (temperature-path)
    mut previous = (cpu-sample)

    loop {
        sleep 5sec
        let current = (cpu-sample)
        print (report $previous $current $temp_path | to json --raw)
        $previous = $current

        if $once { break }
    }
}
