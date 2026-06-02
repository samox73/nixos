use crate::app::App;
use egui;

#[derive(Default, serde::Serialize, serde::Deserialize)]
pub struct OptimizeState {
    pub roi_resource: usize,  // 0=holz 1=marmor 2=kristall 3=schwefel
    pub roi_island_lvl: u32,
    pub roi_town_lvl: u32,
    pub amort_building: usize, // same resource index
    pub amort_from_lvl: u32,
}

pub fn show(app: &mut App, ui: &mut egui::Ui) {
    egui::ScrollArea::vertical().show(ui, |ui| {
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

            let current_level = acc.towns.iter().map(|t| t.stadthaltersitz).max().unwrap_or(0);
            let target_level = n + 1;

            ui.label(format!(
                "Aktuelle Stadtanzahl: {n}  |  Stadthaltersitz-Ziel: Lvl {target_level}"
            ));
            ui.label(format!(
                "Benotigtes Upgrade: {n} bestehende Stadte + 1 neue Stadt = {} Upgrades auf Lvl {target_level}",
                n + 1
            ));
            ui.label(format!("Hochstes SHS-Level in deinen Stadten: {current_level}"));

            ui.add_space(4.0);
            ui.colored_label(
                egui::Color32::GRAY,
                "TODO: Kosten aus Kostentabelle multipliziert mit Rabatt berechnen",
            );

            ui.add_space(4.0);
            egui::Grid::new("shs_cost_grid")
                .striped(true)
                .spacing([12.0, 4.0])
                .show(ui, |ui| {
                    ui.strong("Ressource");
                    ui.strong(format!("Kosten je Upgrade (Lvl {target_level})"));
                    ui.strong(format!("Gesamt (x{})", n + 1));
                    ui.end_row();

                    for res in ["Holz", "Marmor", "Kristall", "Schwefel", "Gold"] {
                        ui.label(res);
                        ui.colored_label(egui::Color32::GRAY, "—");
                        ui.colored_label(egui::Color32::GRAY, "—");
                        ui.end_row();
                    }
                });
        });
}

// ── 2. Insel vs. Stadt ROI ─────────────────────────────────────────────────

const RESOURCES: [&str; 5] = ["Holz", "Wein", "Marmor", "Kristall", "Schwefel"];
const ISLAND_BUILDINGS: [&str; 5] =
    ["Sagewerk", "Weinberg", "Steinbruch", "Kristallmine", "Schwefelgrube"];
const TOWN_BUILDINGS: [&str; 5] =
    ["Forsthaus", "Winzerei", "Steinmetz", "Glasbläserei", "Alchemistenturm"];

fn section_insel_vs_stadt(app: &mut App, ui: &mut egui::Ui) {
    egui::CollapsingHeader::new("Insel- vs. Stadtgebäude ROI")
        .default_open(true)
        .show(ui, |ui| {
            let state = &mut app.optimize;

            ui.horizontal(|ui| {
                ui.label("Ressource:");
                for (i, name) in RESOURCES.iter().enumerate() {
                    ui.selectable_value(&mut state.roi_resource, i, *name);
                }
            });

            let r = state.roi_resource;
            ui.horizontal(|ui| {
                ui.label(format!("{} (Insel) aktuelles Level:", ISLAND_BUILDINGS[r]));
                ui.add(egui::DragValue::new(&mut state.roi_island_lvl).range(0..=50));
            });
            ui.horizontal(|ui| {
                ui.label(format!("{} (Stadt) aktuelles Level:", TOWN_BUILDINGS[r]));
                ui.add(egui::DragValue::new(&mut state.roi_town_lvl).range(0..=30));
            });

            ui.add_space(4.0);
            egui::Grid::new("roi_grid")
                .striped(true)
                .spacing([12.0, 4.0])
                .show(ui, |ui| {
                    ui.strong("Upgrade");
                    ui.strong("Kosten");
                    ui.strong("Zusatzproduktion/h");
                    ui.strong("Amortisation");
                    ui.end_row();

                    let island = format!("{} Lvl {} -> {}", ISLAND_BUILDINGS[r], state.roi_island_lvl, state.roi_island_lvl + 1);
                    let town = format!("{} Lvl {} -> {}", TOWN_BUILDINGS[r], state.roi_town_lvl, state.roi_town_lvl + 1);

                    for label in [island, town] {
                        ui.label(label);
                        ui.colored_label(egui::Color32::GRAY, "—");
                        ui.colored_label(egui::Color32::GRAY, "—");
                        ui.colored_label(egui::Color32::GRAY, "—");
                        ui.end_row();
                    }
                });

            ui.colored_label(egui::Color32::GRAY, "TODO: Produktionsformel + Kostentabelle anwenden");
        });
}

// ── 3. Gebäude-Amortisation ─────────────────────────────────────────────────

fn section_gebaude_amortisation(app: &mut App, ui: &mut egui::Ui) {
    egui::CollapsingHeader::new("Gebäude-Amortisation (Payoff-Zeit)")
        .default_open(true)
        .show(ui, |ui| {
            let state = &mut app.optimize;

            ui.horizontal(|ui| {
                ui.label("Gebäude:");
                for (i, name) in TOWN_BUILDINGS.iter().enumerate() {
                    ui.selectable_value(&mut state.amort_building, i, *name);
                }
            });

            ui.horizontal(|ui| {
                ui.label("Von Level:");
                ui.add(egui::DragValue::new(&mut state.amort_from_lvl).range(0..=50));
            });

            ui.add_space(4.0);
            ui.colored_label(
                egui::Color32::GRAY,
                "TODO: (Upgrade-Kosten) / (Produktionszuwachs/h) = Payoff in Stunden",
            );

            egui::Grid::new("amort_grid")
                .striped(true)
                .spacing([12.0, 4.0])
                .show(ui, |ui| {
                    ui.strong("Stadt");
                    ui.strong("Rabatt");
                    ui.strong("Effektive Kosten");
                    ui.strong("Payoff");
                    ui.end_row();

                    let acc = &app.accounts[app.current_account];
                    for town in &acc.towns {
                        ui.label(&town.name);
                        let discount = match state.amort_building {
                            0 => town.forsthaus,
                            1 => town.winzerei,
                            2 => town.steinmetz,
                            3 => town.glasblaeserei,
                            4 => town.alchemistenturm,
                            _ => 0,
                        };
                        ui.label(format!("{discount}%"));
                        ui.colored_label(egui::Color32::GRAY, "—");
                        ui.colored_label(egui::Color32::GRAY, "—");
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
            ui.colored_label(
                egui::Color32::GRAY,
                "TODO: Lagerkapazitat je Lagerlevel hinzufugen, dann (Kapazitat - Bestand) / Produktion/h",
            );

            egui::Grid::new("overflow_grid")
                .striped(true)
                .spacing([12.0, 4.0])
                .show(ui, |ui| {
                    ui.strong("Stadt");
                    ui.strong("Lager-Lvl");
                    ui.strong("Holz/h");
                    ui.strong("Sekundär/h");
                    ui.end_row();

                    let acc = &app.accounts[app.current_account];
                    let islands = &acc.islands;
                    for town in &acc.towns {
                        let holz_rate = town.holz_production();
                        let sec_rate = town
                            .island_id
                            .and_then(|id| islands.get(id))
                            .map(|isl| town.secondary_production(isl.resource))
                            .unwrap_or(0.0);
                        ui.label(&town.name);
                        ui.label(town.warehouse_level.to_string());
                        for rate in [holz_rate, sec_rate] {
                            if rate <= 0.0 {
                                ui.label("—");
                            } else {
                                ui.colored_label(egui::Color32::GRAY, "?h");
                            }
                        }
                        ui.end_row();
                    }
                });
        });
}
