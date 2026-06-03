use crate::app::App;
use crate::model::IslandResource;
use crate::tables;
use egui;

#[derive(Default, serde::Serialize, serde::Deserialize)]
pub struct OptimizeState {
    pub roi_resource: usize,   // 0=holz 1=wein 2=marmor 3=kristall 4=schwefel
    pub amort_building: usize, // same resource index
}

pub fn show(app: &mut App, ui: &mut egui::Ui) {
    egui::ScrollArea::vertical().auto_shrink([false, false]).show(ui, |ui| {
        section_nachste_stadt(app, ui);
        ui.add_space(8.0);
        section_insel_vs_stadt(app, ui);
        ui.add_space(8.0);
        section_gebaude_amortisation(app, ui);
        ui.add_space(8.0);
        section_lager_uberlauf(app, ui);
    });
}

// ── 1. Nächste Stadt ────────────────────────────────────────────────────────

fn section_nachste_stadt(app: &App, ui: &mut egui::Ui) {
    egui::CollapsingHeader::new("Nächste Stadt (Stadthaltersitz-Kosten)")
        .default_open(true)
        .show(ui, |ui| {
            let acc = &app.accounts[app.current_account];
            let n = acc.towns.len() as u32;

            if n == 0 {
                ui.label("Keine Städte vorhanden.");
                return;
            }

            // To unlock the (n+1)th city, both SHS and Palast must be at level n.
            let target_level = n;
            let non_capital = n.saturating_sub(if acc.capital_town.is_some() { 1 } else { 0 });
            let has_capital = acc.capital_town.is_some();
            let shs_table = tables::stadthaltersitz();
            let palast_table = tables::palast();
            let idx = target_level.saturating_sub(1) as usize;

            ui.label(format!(
                "Aktuelle Stadtanzahl: {n}  |  Ziel-Level: {target_level}"
            ));

            ui.add_space(4.0);

            let shs_cost = shs_table.get(idx);
            let palast_cost = if has_capital { palast_table.get(idx) } else { None };

            // Combined cost per resource: SHS × non_capital + Palast × 1
            let combined = |shs: u64, pal: u64| -> u64 {
                shs * non_capital as u64 + if has_capital { pal } else { 0 }
            };

            // Aggregate stocks and production rates across all towns.
            // Index: 0=Holz, 1=Wein, 2=Marmor, 3=Kristall, 4=Schwefel
            let settings = acc.settings;
            let theater_holz_town = acc.theater_holz_town;
            let theater_secondary_town = acc.theater_secondary_town;
            let mut stocks = [0u64; 5];
            let mut rates  = [0.0f64; 5];
            for (ti, town) in acc.towns.iter().enumerate() {
                let th = theater_holz_town == Some(ti);
                let ts = theater_secondary_town == Some(ti);
                stocks[0] += town.holz_stock;
                rates[0]  += town.holz_production(&settings, th);
                if let Some(isl) = town.island_id.and_then(|id| acc.islands.get(id)) {
                    let ri = isl.resource as usize + 1; // Wein=1 … Schwefel=4
                    stocks[ri] += town.secondary_stock;
                    rates[ri]  += town.secondary_production(isl.resource, &settings, ts);
                }
            }

            let shs_vals = shs_cost.map(|c| [c.holz, c.wein, c.marmor, c.kristall, c.schwefel]);
            let pal_vals = palast_cost.map(|c| [c.holz, c.wein, c.marmor, c.kristall, c.schwefel]);
            let resource_names = ["Holz", "Wein", "Marmor", "Kristall", "Schwefel"];

            // Time (hours) until enough of each resource is available
            let wait_h = |needed: u64, stock: u64, rate: f64| -> f64 {
                if stock >= needed { 0.0 }
                else if rate <= 0.0 { f64::INFINITY }
                else { (needed - stock) as f64 / rate }
            };

            let mut bottleneck_h = 0.0_f64;

            egui::Grid::new("shs_cost_grid")
                .striped(true)
                .spacing([12.0, 4.0])
                .show(ui, |ui| {
                    ui.strong("Ressource");
                    ui.strong(format!("SHS (x{non_capital})"));
                    if has_capital { ui.strong("Palast (x1)"); }
                    ui.strong("Gesamt");
                    ui.strong("Bestand");
                    ui.strong("Produktion/h");
                    ui.strong("Bereit in");
                    ui.end_row();

                    for (i, name) in resource_names.iter().enumerate() {
                        let shs_v = shs_vals.map(|v| v[i]).unwrap_or(0);
                        let pal_v = pal_vals.map(|v| v[i]).unwrap_or(0);
                        let total = combined(shs_v, pal_v);
                        if total == 0 { continue; }

                        let w = wait_h(total, stocks[i], rates[i]);
                        bottleneck_h = bottleneck_h.max(w);

                        ui.label(*name);
                        cost_cell(ui, shs_v, non_capital as u64);
                        if has_capital { cost_cell(ui, pal_v, 1); }
                        ui.label(format!("{total}"));
                        ui.label(format!("{}", stocks[i]));
                        if rates[i] > 0.0 {
                            ui.label(format!("{:.1}", rates[i]));
                        } else {
                            ui.colored_label(egui::Color32::GRAY, "—");
                        }
                        if w == 0.0 {
                            ui.colored_label(egui::Color32::GREEN, "Bereit");
                        } else {
                            ui.label(tables::fmt_overflow(w));
                        }
                        ui.end_row();
                    }

                    // Duration row
                    let shs_dur = shs_cost.map(|c| c.dauer_secs).unwrap_or(0);
                    let pal_dur = palast_cost.map(|c| c.dauer_secs).unwrap_or(0);
                    ui.label("Bauzeit");
                    ui.label(if shs_cost.is_some() { tables::fmt_duration(shs_dur) } else { "—".to_string() });
                    if has_capital {
                        ui.label(if palast_cost.is_some() { tables::fmt_duration(pal_dur) } else { "—".to_string() });
                    }
                    ui.label(tables::fmt_duration(shs_dur.max(pal_dur)));
                    ui.colored_label(egui::Color32::GRAY, "—");
                    ui.colored_label(egui::Color32::GRAY, "—");
                    ui.colored_label(egui::Color32::GRAY, "—");
                    ui.end_row();
                });

            ui.add_space(4.0);
            if bottleneck_h == 0.0 {
                ui.colored_label(egui::Color32::GREEN, "Alle Ressourcen vorhanden — Upgrades können gestartet werden.");
            } else if bottleneck_h.is_infinite() {
                ui.colored_label(egui::Color32::RED, "Fehlende Produktion — nicht alle Ressourcen werden produziert.");
            } else {
                ui.label(format!("Alle Ressourcen bereit in: {}", tables::fmt_overflow(bottleneck_h)));
            }

            if shs_cost.is_none() {
                ui.colored_label(
                    egui::Color32::GRAY,
                    format!("Keine Tabellendaten für Lvl {target_level} vorhanden."),
                );
            }
        });
}

// ── 2. Insel vs. Stadt ROI ─────────────────────────────────────────────────

const RESOURCES: [&str; 5] = ["Holz", "Wein", "Marmor", "Kristall", "Schwefel"];
const ISLAND_BUILDINGS: [&str; 5] =
    ["Sägewerk", "Luxusgüter", "Luxusgüter", "Luxusgüter", "Luxusgüter"];
const TOWN_BUILDINGS: [&str; 5] =
    ["Forsthaus", "Winzerei", "Steinmetz", "Glasbläserei", "Alchemistenturm"];

fn section_insel_vs_stadt(app: &mut App, ui: &mut egui::Ui) {
    egui::CollapsingHeader::new("Insel- vs. Stadtgebäude ROI")
        .default_open(true)
        .show(ui, |ui| {
            let r = app.optimize.roi_resource;
            let acc = &app.accounts[app.current_account];
            let settings = acc.settings;
            let theater_holz_town = acc.theater_holz_town;
            let theater_secondary_town = acc.theater_secondary_town;

            ui.horizontal(|ui| {
                ui.label("Ressource:");
                for (i, name) in RESOURCES.iter().enumerate() {
                    ui.selectable_value(&mut app.optimize.roi_resource, i, *name);
                }
            });

            let r = if r != app.optimize.roi_resource { app.optimize.roi_resource } else { r };
            let acc = &app.accounts[app.current_account];

            ui.add_space(4.0);

            // ── Island building upgrades ──────────────────────────────────────
            ui.strong(format!("Inselgebäude: {}", ISLAND_BUILDINGS[r]));
            egui::Grid::new("roi_island_grid")
                .striped(true)
                .spacing([12.0, 4.0])
                .show(ui, |ui| {
                    ui.strong("Insel");
                    ui.strong("Lvl");
                    ui.strong("Kosten (Holz)");
                    ui.strong("Dauer");
                    ui.strong("+Arbeiter");
                    ui.strong("+Produktion/h");
                    ui.strong("Amortisation");
                    ui.end_row();

                    for island in &acc.islands {
                        // For holz (r==0), all islands have Sägewerk.
                        // For secondary (r>0), only islands matching the resource type.
                        let is_relevant = r == 0 || island.resource == idx_to_resource(r);
                        if !is_relevant {
                            continue;
                        }

                        let current_lvl = if r == 0 { island.sagewerk } else { island.resource_level } as usize;
                        let table = if r == 0 { tables::sagewerk() } else { tables::luxusgueter() };

                        let Some(row) = table.get(current_lvl) else {
                            ui.label(&island.name);
                            ui.label(current_lvl.to_string());
                            ui.colored_label(egui::Color32::GRAY, "Max");
                            ui.end_row();
                            continue;
                        };

                        let old_workers = if current_lvl > 0 {
                            table.get(current_lvl - 1).map(|r| r.workers).unwrap_or(0)
                        } else {
                            0
                        };
                        let delta_workers = row.workers.saturating_sub(old_workers);

                        // Sum multipliers over all towns on this island
                        let towns_on_island: Vec<usize> = acc
                            .towns
                            .iter()
                            .enumerate()
                            .filter(|(_, t)| {
                                t.island_id.map(|id| &acc.islands[id] as *const _ == island as *const _).unwrap_or(false)
                            })
                            .map(|(i, _)| i)
                            .collect();

                        let n_towns = towns_on_island.len().max(1);
                        let sum_mult: f64 = towns_on_island.iter().map(|&ti| {
                            let t = &acc.towns[ti];
                            if r == 0 {
                                let theater = theater_holz_town == Some(ti);
                                t.holz_production(&settings, theater) / t.holz_workers.max(1) as f64
                            } else {
                                let theater = theater_secondary_town == Some(ti);
                                let res = idx_to_resource(r);
                                t.secondary_production(res, &settings, theater) / t.secondary_workers.max(1) as f64
                            }
                        }).sum();
                        let avg_mult = sum_mult / n_towns as f64;

                        let prod_gain = delta_workers as f64 * avg_mult;
                        let payoff = if prod_gain > 0.0 {
                            row.upgrade_holz as f64 / prod_gain
                        } else {
                            f64::INFINITY
                        };

                        ui.label(&island.name);
                        ui.label(format!("{} -> {}", current_lvl, current_lvl + 1));
                        ui.label(format!("{}", row.upgrade_holz));
                        ui.label(tables::fmt_duration(row.dauer_secs));
                        ui.label(format!("+{delta_workers}"));
                        ui.label(format!("{prod_gain:.1}/h"));
                        ui.label(tables::fmt_overflow(payoff));
                        ui.end_row();
                    }
                });

            ui.add_space(4.0);

            // ── Town building upgrades ─────────────────────────────────────────
            ui.strong(format!("Stadtgebäude: {}", TOWN_BUILDINGS[r]));
            egui::Grid::new("roi_town_grid")
                .striped(true)
                .spacing([12.0, 4.0])
                .show(ui, |ui| {
                    ui.strong("Stadt");
                    ui.strong("Lvl");
                    ui.strong("Kosten");
                    ui.strong("Dauer");
                    ui.strong("+Produktion/h");
                    ui.strong("Amortisation");
                    ui.end_row();

                    for town in acc.towns.iter() {
                        let (current_lvl, workers) = if r == 0 {
                            (town.forsthaus as usize, town.holz_workers)
                        } else {
                            // Only towns on matching islands benefit
                            let res = idx_to_resource(r);
                            let on_matching = town.island_id
                                .map(|id| acc.islands[id].resource == res)
                                .unwrap_or(false);
                            if !on_matching {
                                continue;
                            }
                            (town.secondary_building_level(res) as usize, town.secondary_workers)
                        };

                        let table = town_building_table(r);
                        let Some(row) = table.get(current_lvl) else {
                            ui.label(&town.name);
                            ui.label(current_lvl.to_string());
                            ui.colored_label(egui::Color32::GRAY, "Max");
                            ui.end_row();
                            continue;
                        };

                        let holz_eff = row.holz as f64 * discount(town.zimmerei);
                        let marmor_eff = row.marmor as f64 * discount(town.architekturburo);
                        let cost_sum = holz_eff + marmor_eff;

                        let prod_gain = workers as f64 * 0.02;
                        let payoff = if prod_gain > 0.0 { cost_sum / prod_gain } else { f64::INFINITY };

                        ui.label(&town.name);
                        ui.label(format!("{} -> {}", current_lvl, current_lvl + 1));
                        ui.label(format!("{:.0}", cost_sum));
                        ui.label(tables::fmt_duration(row.dauer_secs));
                        ui.label(format!("{prod_gain:.1}/h"));
                        ui.label(tables::fmt_overflow(payoff));
                        ui.end_row();
                    }
                });
        });
}

// ── 3. Gebäude-Amortisation ─────────────────────────────────────────────────

fn section_gebaude_amortisation(app: &mut App, ui: &mut egui::Ui) {
    egui::CollapsingHeader::new("Gebäude-Amortisation (Payoff-Zeit)")
        .default_open(true)
        .show(ui, |ui| {
            ui.horizontal(|ui| {
                ui.label("Gebäude:");
                for (i, name) in TOWN_BUILDINGS.iter().enumerate() {
                    ui.selectable_value(&mut app.optimize.amort_building, i, *name);
                }
            });

            let b = app.optimize.amort_building;
            let acc = &app.accounts[app.current_account];

            ui.add_space(4.0);
            egui::Grid::new("amort_grid")
                .striped(true)
                .spacing([12.0, 4.0])
                .show(ui, |ui| {
                    ui.strong("Stadt");
                    ui.strong("Lvl");
                    ui.strong("Kosten (Holz)");
                    ui.strong("Kosten (Marmor)");
                    ui.strong("Eff. Kosten");
                    ui.strong("+Produktion/h");
                    ui.strong("Payoff");
                    ui.end_row();

                    for town in &acc.towns {
                        let (current_lvl, workers) = building_level_and_workers(b, town);

                        if workers == 0 && b != 0 {
                            // Town has no workers for this resource — skip or show greyed
                            let res = idx_to_resource(b);
                            let on_matching = town.island_id
                                .map(|id| acc.islands[id].resource == res)
                                .unwrap_or(false);
                            if !on_matching {
                                continue;
                            }
                        }

                        let table = town_building_table(b);
                        let Some(row) = table.get(current_lvl as usize) else {
                            ui.label(&town.name);
                            ui.label(current_lvl.to_string());
                            ui.colored_label(egui::Color32::GRAY, "Max");
                            ui.end_row();
                            continue;
                        };

                        // Per-resource construction discounts (1% per building level)
                        let holz_discount = discount(town.zimmerei);
                        let marmor_discount = discount(town.architekturburo);

                        let holz_base = row.holz as f64;
                        let marmor_base = row.marmor as f64;
                        let holz_eff = holz_base * holz_discount;
                        let marmor_eff = marmor_base * marmor_discount;
                        let cost_sum = holz_eff + marmor_eff;

                        let prod_gain = workers as f64 * 0.02;
                        let payoff = if prod_gain > 0.0 { cost_sum / prod_gain } else { f64::INFINITY };

                        ui.label(&town.name);
                        ui.label(format!("{} -> {}", current_lvl, current_lvl + 1));
                        if row.holz > 0 {
                            ui.label(format!("{} (−{}%)", row.holz, town.zimmerei));
                        } else {
                            ui.colored_label(egui::Color32::GRAY, "—");
                        }
                        if row.marmor > 0 {
                            ui.label(format!("{} (−{}%)", row.marmor, town.architekturburo));
                        } else {
                            ui.colored_label(egui::Color32::GRAY, "—");
                        }
                        ui.label(format!("{cost_sum:.0}"));
                        ui.label(format!("{prod_gain:.1}/h"));
                        ui.label(tables::fmt_overflow(payoff));
                        ui.end_row();
                    }
                });
        });
}

// ── 4. Lager-Überlauf ────────────────────────────────────────────────────────

fn section_lager_uberlauf(app: &App, ui: &mut egui::Ui) {
    egui::CollapsingHeader::new("Lager-Überlauf (Zeit bis voll)")
        .default_open(true)
        .show(ui, |ui| {
            let settings = app.accounts[app.current_account].settings;
            let acc = &app.accounts[app.current_account];
            let islands = &acc.islands;
            let theater_holz_town = acc.theater_holz_town;
            let theater_secondary_town = acc.theater_secondary_town;

            egui::Grid::new("overflow_grid")
                .striped(true)
                .spacing([12.0, 4.0])
                .show(ui, |ui| {
                    ui.strong("Stadt");
                    ui.strong("Lager-Lvl");
                    ui.strong("Kapazität");
                    ui.strong("Holz/h");
                    ui.strong("Holz-Bestand");
                    ui.strong("Überlauf Holz");
                    ui.strong("Sekundär/h");
                    ui.strong("Sek.-Bestand");
                    ui.strong("Überlauf Sek.");
                    ui.end_row();

                    for (idx, town) in acc.towns.iter().enumerate() {
                        let theater_holz = theater_holz_town == Some(idx);
                        let theater_sec = theater_secondary_town == Some(idx);
                        let capacity = tables::warehouse_capacity(town.warehouse_level);
                        let holz_rate = town.holz_production(&settings, theater_holz);
                        let sec_rate = town
                            .island_id
                            .and_then(|id| islands.get(id))
                            .map(|isl| town.secondary_production(isl.resource, &settings, theater_sec))
                            .unwrap_or(0.0);

                        let holz_overflow = if holz_rate > 0.0 {
                            capacity.saturating_sub(town.holz_stock) as f64 / holz_rate
                        } else {
                            f64::INFINITY
                        };
                        let sec_overflow = if sec_rate > 0.0 {
                            capacity.saturating_sub(town.secondary_stock) as f64 / sec_rate
                        } else {
                            f64::INFINITY
                        };

                        ui.label(&town.name);
                        ui.label(town.warehouse_level.to_string());
                        ui.label(format!("{}", capacity));

                        if holz_rate <= 0.0 {
                            ui.label("—");
                        } else {
                            ui.label(format!("{holz_rate:.1}"));
                        }
                        ui.label(format!("{}", town.holz_stock));
                        ui.colored_label(
                            egui::Color32::GRAY,
                            format!("Voll in {}", tables::fmt_overflow(holz_overflow)),
                        );

                        if sec_rate <= 0.0 {
                            ui.label("—");
                        } else {
                            ui.label(format!("{sec_rate:.1}"));
                        }
                        ui.label(format!("{}", town.secondary_stock));
                        ui.colored_label(
                            egui::Color32::GRAY,
                            format!("Voll in {}", tables::fmt_overflow(sec_overflow)),
                        );

                        ui.end_row();
                    }
                });
        });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

fn idx_to_resource(i: usize) -> IslandResource {
    match i {
        1 => IslandResource::Wein,
        2 => IslandResource::Marmor,
        3 => IslandResource::Kristall,
        _ => IslandResource::Schwefel,
    }
}

fn town_building_table(resource_idx: usize) -> &'static [crate::tables::UpgradeCost] {
    match resource_idx {
        0 => tables::forsthaus(),
        1 => tables::winzerei(),
        2 => tables::steinmetz(),
        3 => tables::glasblaeserei(),
        _ => tables::alchemistenturm(),
    }
}

/// Returns (current_level, workers) for the given building index.
fn building_level_and_workers(b: usize, town: &crate::model::Town) -> (u32, u32) {
    match b {
        0 => (town.forsthaus, town.holz_workers),
        1 => (town.winzerei, town.secondary_workers),
        2 => (town.steinmetz, town.secondary_workers),
        3 => (town.glasblaeserei, town.secondary_workers),
        _ => (town.alchemistenturm, town.secondary_workers),
    }
}

/// Renders a cost cell: "N" if cost > 0 and count > 1, "—" if cost == 0.
fn cost_cell(ui: &mut egui::Ui, cost: u64, _count: u64) {
    if cost > 0 {
        ui.label(format!("{cost}"));
    } else {
        ui.colored_label(egui::Color32::GRAY, "—");
    }
}

/// Construction cost multiplier after discount (1% per level of the reduction building).
fn discount(building_level: u32) -> f64 {
    (1.0 - building_level as f64 * 0.01).max(0.0)
}
