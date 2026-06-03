#![allow(dead_code)]
use std::sync::OnceLock;

use crate::model::IslandResource;

// ── Cost structs ──────────────────────────────────────────────────────────────

pub struct UpgradeCost {
    pub holz: u64,
    pub marmor: u64,
    pub dauer_secs: u32,
}

pub struct IslandBuildingLevel {
    pub upgrade_holz: u64,
    pub dauer_secs: u32,
    pub workers: u32,
}

pub struct WarehouseLevel {
    pub holz: u64,
    pub marmor: u64,
    pub dauer_secs: u32,
    pub capacity: u64,
}

pub struct FullCost {
    pub holz: u64,
    pub wein: u64,
    pub marmor: u64,
    pub kristall: u64,
    pub schwefel: u64,
    pub dauer_secs: u32,
}

// ── CSV parsing helpers ────────────────────────────────────────────────────────

fn parse_u64(s: &str) -> u64 {
    s.trim().parse().unwrap_or(0)
}

fn parse_u32(s: &str) -> u32 {
    s.trim().parse().unwrap_or(0)
}

/// Parse Stufe,Holz,Marmor,Dauer CSV (skip header line)
fn parse_upgrade_cost(csv: &str) -> Vec<UpgradeCost> {
    csv.lines()
        .skip(1) // skip header
        .filter(|l| !l.trim().is_empty())
        .map(|line| {
            let mut cols = line.split(',');
            let _stufe = cols.next().unwrap_or("");
            let holz = parse_u64(cols.next().unwrap_or("0"));
            let marmor = parse_u64(cols.next().unwrap_or("0"));
            let dauer_secs = parse_u32(cols.next().unwrap_or("0"));
            UpgradeCost { holz, marmor, dauer_secs }
        })
        .collect()
}

/// Parse Stufe,Holz,Dauer,Arbeiter CSV (skip header)
fn parse_island_building(csv: &str) -> Vec<IslandBuildingLevel> {
    csv.lines()
        .skip(1)
        .filter(|l| !l.trim().is_empty())
        .map(|line| {
            let mut cols = line.split(',');
            let _stufe = cols.next().unwrap_or("");
            let holz = parse_u64(cols.next().unwrap_or("0"));
            let dauer_secs = parse_u32(cols.next().unwrap_or("0"));
            let workers = parse_u32(cols.next().unwrap_or("0"));
            IslandBuildingLevel { upgrade_holz: holz, dauer_secs, workers }
        })
        .collect()
}

/// Parse Stufe,Arbeiter,Holz,Dauer CSV (skip header) - Luxusgüter format
fn parse_luxusgueter(csv: &str) -> Vec<IslandBuildingLevel> {
    csv.lines()
        .skip(1)
        .filter(|l| !l.trim().is_empty())
        .map(|line| {
            let mut cols = line.split(',');
            let _stufe = cols.next().unwrap_or("");
            let workers = parse_u32(cols.next().unwrap_or("0"));
            let holz = parse_u64(cols.next().unwrap_or("0"));
            let dauer_secs = parse_u32(cols.next().unwrap_or("0"));
            IslandBuildingLevel { upgrade_holz: holz, dauer_secs, workers }
        })
        .collect()
}

/// Parse Stufe,Holz,Marmor,Dauer,Kapazität CSV (skip header)
fn parse_warehouse(csv: &str) -> Vec<WarehouseLevel> {
    csv.lines()
        .skip(1)
        .filter(|l| !l.trim().is_empty())
        .map(|line| {
            let mut cols = line.split(',');
            let _stufe = cols.next().unwrap_or("");
            let holz = parse_u64(cols.next().unwrap_or("0"));
            let marmor = parse_u64(cols.next().unwrap_or("0"));
            let dauer_secs = parse_u32(cols.next().unwrap_or("0"));
            let capacity = parse_u64(cols.next().unwrap_or("0"));
            WarehouseLevel { holz, marmor, dauer_secs, capacity }
        })
        .collect()
}

/// Parse Stufe,Holz,Wein,Marmor,Kristall,Schwefel,Dauer CSV (skip header)
fn parse_full_cost(csv: &str) -> Vec<FullCost> {
    csv.lines()
        .skip(1)
        .filter(|l| !l.trim().is_empty())
        .map(|line| {
            let mut cols = line.split(',');
            let _stufe = cols.next().unwrap_or("");
            let holz = parse_u64(cols.next().unwrap_or("0"));
            let wein = parse_u64(cols.next().unwrap_or("0"));
            let marmor = parse_u64(cols.next().unwrap_or("0"));
            let kristall = parse_u64(cols.next().unwrap_or("0"));
            let schwefel = parse_u64(cols.next().unwrap_or("0"));
            let dauer_secs = parse_u32(cols.next().unwrap_or("0"));
            FullCost { holz, wein, marmor, kristall, schwefel, dauer_secs }
        })
        .collect()
}

// ── Static tables ──────────────────────────────────────────────────────────────

pub fn forsthaus() -> &'static [UpgradeCost] {
    static TABLE: OnceLock<Vec<UpgradeCost>> = OnceLock::new();
    TABLE.get_or_init(|| parse_upgrade_cost(include_str!("../data/Forsthaus.csv")))
}

pub fn steinmetz() -> &'static [UpgradeCost] {
    static TABLE: OnceLock<Vec<UpgradeCost>> = OnceLock::new();
    TABLE.get_or_init(|| parse_upgrade_cost(include_str!("../data/Steinmetz.csv")))
}

pub fn winzerei() -> &'static [UpgradeCost] {
    static TABLE: OnceLock<Vec<UpgradeCost>> = OnceLock::new();
    TABLE.get_or_init(|| parse_upgrade_cost(include_str!("../data/Winzerei.csv")))
}

pub fn glasblaeserei() -> &'static [UpgradeCost] {
    static TABLE: OnceLock<Vec<UpgradeCost>> = OnceLock::new();
    TABLE.get_or_init(|| parse_upgrade_cost(include_str!("../data/Glasbläserei.csv")))
}

pub fn alchemistenturm() -> &'static [UpgradeCost] {
    static TABLE: OnceLock<Vec<UpgradeCost>> = OnceLock::new();
    TABLE.get_or_init(|| parse_upgrade_cost(include_str!("../data/Alchemistenturm.csv")))
}

pub fn zimmerei() -> &'static [UpgradeCost] {
    static TABLE: OnceLock<Vec<UpgradeCost>> = OnceLock::new();
    TABLE.get_or_init(|| parse_upgrade_cost(include_str!("../data/Zimmerei.csv")))
}

pub fn kelterei() -> &'static [UpgradeCost] {
    static TABLE: OnceLock<Vec<UpgradeCost>> = OnceLock::new();
    TABLE.get_or_init(|| parse_upgrade_cost(include_str!("../data/Kelterei.csv")))
}

pub fn architekturburo() -> &'static [UpgradeCost] {
    static TABLE: OnceLock<Vec<UpgradeCost>> = OnceLock::new();
    TABLE.get_or_init(|| parse_upgrade_cost(include_str!("../data/Architekturbüro.csv")))
}

pub fn optiker() -> &'static [UpgradeCost] {
    static TABLE: OnceLock<Vec<UpgradeCost>> = OnceLock::new();
    TABLE.get_or_init(|| parse_upgrade_cost(include_str!("../data/Optiker.csv")))
}

pub fn feuerwerksplatz() -> &'static [UpgradeCost] {
    static TABLE: OnceLock<Vec<UpgradeCost>> = OnceLock::new();
    TABLE.get_or_init(|| parse_upgrade_cost(include_str!("../data/Feuerwerksplatz.csv")))
}

pub fn sagewerk() -> &'static [IslandBuildingLevel] {
    static TABLE: OnceLock<Vec<IslandBuildingLevel>> = OnceLock::new();
    TABLE.get_or_init(|| parse_island_building(include_str!("../data/Sägewerk.csv")))
}

pub fn luxusgueter() -> &'static [IslandBuildingLevel] {
    static TABLE: OnceLock<Vec<IslandBuildingLevel>> = OnceLock::new();
    TABLE.get_or_init(|| parse_luxusgueter(include_str!("../data/Luxusgüter.csv")))
}

pub fn lagerhaus() -> &'static [WarehouseLevel] {
    static TABLE: OnceLock<Vec<WarehouseLevel>> = OnceLock::new();
    TABLE.get_or_init(|| parse_warehouse(include_str!("../data/Lagerhaus.csv")))
}

pub fn stadthaltersitz() -> &'static [FullCost] {
    static TABLE: OnceLock<Vec<FullCost>> = OnceLock::new();
    TABLE.get_or_init(|| parse_full_cost(include_str!("../data/Stadthaltersitz.csv")))
}

pub fn palast() -> &'static [FullCost] {
    static TABLE: OnceLock<Vec<FullCost>> = OnceLock::new();
    TABLE.get_or_init(|| parse_full_cost(include_str!("../data/Palast.csv")))
}

// ── Utility functions ─────────────────────────────────────────────────────────

/// Returns warehouse capacity for the given level.
/// Clamps to max table entry if level is out of range.
pub fn warehouse_capacity(level: u32) -> u64 {
    let table = lagerhaus();
    if table.is_empty() {
        return 0;
    }
    if level == 0 {
        return 0;
    }
    // table[k] = level k+1, so table[level-1] = capacity at `level`
    let idx = (level as usize).saturating_sub(1).min(table.len() - 1);
    table[idx].capacity
}

/// Dispatch to the right production building upgrade table for IslandResource.
pub fn prod_building_table(resource: IslandResource) -> &'static [UpgradeCost] {
    match resource {
        IslandResource::Wein => winzerei(),
        IslandResource::Marmor => steinmetz(),
        IslandResource::Kristall => glasblaeserei(),
        IslandResource::Schwefel => alchemistenturm(),
    }
}

/// Format duration in seconds as human-readable string, e.g. "3h 05m" or "5d 12h".
pub fn fmt_duration(secs: u32) -> String {
    let minutes = secs / 60;
    let hours = minutes / 60;
    let days = hours / 24;

    if days > 0 {
        let remaining_hours = hours % 24;
        format!("{}d {:02}h", days, remaining_hours)
    } else if hours > 0 {
        let remaining_mins = minutes % 60;
        format!("{}h {:02}m", hours, remaining_mins)
    } else {
        format!("{}m", minutes)
    }
}

/// Format overflow time in hours as human-readable string.
/// Returns "∞" for infinite (zero or negative production).
pub fn fmt_overflow(hours: f64) -> String {
    if hours.is_infinite() || hours.is_nan() || hours < 0.0 {
        return "∞".to_string();
    }
    let total_minutes = (hours * 60.0).round() as u64;
    let total_hours = total_minutes / 60;
    let days = total_hours / 24;

    if days > 0 {
        let remaining_hours = total_hours % 24;
        format!("{}d {}h", days, remaining_hours)
    } else if total_hours > 0 {
        let remaining_mins = total_minutes % 60;
        format!("{}h {:02}m", total_hours, remaining_mins)
    } else {
        format!("{}m", total_minutes)
    }
}
