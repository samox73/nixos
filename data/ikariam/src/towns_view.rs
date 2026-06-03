use crate::app::App;
use crate::model::{
    IslandResource, ProductionSettings, Town, COLOR_HOLZ, COLOR_KRISTALL, COLOR_MARMOR,
    COLOR_SCHWEFEL, COLOR_WEIN,
};
use crate::tables;
use egui;

#[derive(Default, serde::Serialize, serde::Deserialize)]
pub struct TownsViewState {
    pub selected_town: Option<usize>,
}

pub fn show(app: &mut App, ui: &mut egui::Ui) {
    let acc = app.current_account;
    let n = app.accounts[acc].towns.len();

    // Clamp selection to valid range
    if let Some(idx) = app.towns_view.selected_town {
        if idx >= n {
            app.towns_view.selected_town = if n > 0 { Some(n - 1) } else { None };
        }
    }
    if app.towns_view.selected_town.is_none() && n > 0 {
        app.towns_view.selected_town = Some(0);
    }

    // Collect island data upfront (avoids borrow conflict with towns later)
    let island_names: Vec<String> = app.accounts[acc]
        .islands
        .iter()
        .map(|i| i.name.clone())
        .collect();
    let island_resources: Vec<IslandResource> = app.accounts[acc]
        .islands
        .iter()
        .map(|i| i.resource)
        .collect();

    // Collect town names for theater dropdowns
    let town_names: Vec<String> = app.accounts[acc]
        .towns
        .iter()
        .map(|t| t.name.clone())
        .collect();

    // ── Settings bar ──────────────────────────────────────────────────────────
    {
        let acc_data = &mut app.accounts[acc];
        let settings = &mut acc_data.settings;
        let theater_holz_town = &mut acc_data.theater_holz_town;
        let theater_secondary_town = &mut acc_data.theater_secondary_town;

        egui::Frame::group(ui.style()).show(ui, |ui| {
            ui.strong("Einstellungen:");
            ui.add_space(2.0);

            egui::Grid::new("settings_grid")
                .spacing([10.0, 3.0])
                .show(ui, |ui| {
                    ui.strong("Ressource");
                    ui.strong("Premium (+20%)");
                    ui.strong("Serverbonus");
                    ui.end_row();

                    settings_row(
                        ui,
                        "Holz",
                        COLOR_HOLZ,
                        &mut settings.premium_holz,
                        &mut settings.temp_holz,
                    );
                    settings_row(
                        ui,
                        "Wein",
                        COLOR_WEIN,
                        &mut settings.premium_wein,
                        &mut settings.temp_wein,
                    );
                    settings_row(
                        ui,
                        "Marmor",
                        COLOR_MARMOR,
                        &mut settings.premium_marmor,
                        &mut settings.temp_marmor,
                    );
                    settings_row(
                        ui,
                        "Kristall",
                        COLOR_KRISTALL,
                        &mut settings.premium_kristall,
                        &mut settings.temp_kristall,
                    );
                    settings_row(
                        ui,
                        "Schwefel",
                        COLOR_SCHWEFEL,
                        &mut settings.premium_schwefel,
                        &mut settings.temp_schwefel,
                    );
                });

            ui.add_space(4.0);
            ui.horizontal(|ui| {
                ui.label("Theater Holz:");
                let sel_holz = (*theater_holz_town)
                    .and_then(|i| town_names.get(i).cloned())
                    .unwrap_or_else(|| "—".to_string());
                egui::ComboBox::from_id_salt("theater_holz")
                    .selected_text(sel_holz)
                    .show_ui(ui, |ui| {
                        ui.selectable_value(theater_holz_town, None, "—");
                        for (i, name) in town_names.iter().enumerate() {
                            ui.selectable_value(theater_holz_town, Some(i), name.as_str());
                        }
                    });

                ui.separator();
                ui.label("Theater Sekundär:");
                let sel_sec = (*theater_secondary_town)
                    .and_then(|i| town_names.get(i).cloned())
                    .unwrap_or_else(|| "—".to_string());
                egui::ComboBox::from_id_salt("theater_secondary")
                    .selected_text(sel_sec)
                    .show_ui(ui, |ui| {
                        ui.selectable_value(theater_secondary_town, None, "—");
                        for (i, name) in town_names.iter().enumerate() {
                            ui.selectable_value(theater_secondary_town, Some(i), name.as_str());
                        }
                    });
            });
        });
    }

    ui.add_space(4.0);

    // ── Totals bar ────────────────────────────────────────────────────────
    {
        let settings = app.accounts[acc].settings;
        let theater_holz_town = app.accounts[acc].theater_holz_town;
        let theater_secondary_town = app.accounts[acc].theater_secondary_town;
        let towns = &app.accounts[acc].towns;
        let mut total_holz = 0.0_f64;
        let mut totals = [0.0_f64; 4]; // indexed by IslandResource discriminant
        for (idx, t) in towns.iter().enumerate() {
            let th = theater_holz_town == Some(idx);
            let ts = theater_secondary_town == Some(idx);
            total_holz += t.holz_production(&settings, th);
            if let Some(res) = t.island_id.and_then(|id| island_resources.get(id).copied()) {
                totals[res as usize] += t.secondary_production(res, &settings, ts);
            }
        }
        egui::Frame::group(ui.style()).show(ui, |ui| {
            ui.horizontal(|ui| {
                ui.strong("Gesamt:");
                ui.separator();
                prod_label(ui, "Holz", COLOR_HOLZ, total_holz);
                for res in [
                    IslandResource::Wein,
                    IslandResource::Marmor,
                    IslandResource::Kristall,
                    IslandResource::Schwefel,
                ] {
                    let v = totals[res as usize];
                    if v > 0.0 {
                        prod_label(ui, res.label(), res.color(), v);
                    }
                }
            });
        });
    }

    ui.add_space(4.0);

    // ── Town tab bar ──────────────────────────────────────────────────────────
    let mut to_select: Option<usize> = None;
    let mut add_town = false;

    ui.horizontal(|ui| {
        for i in 0..app.accounts[acc].towns.len() {
            let name = app.accounts[acc].towns[i].name.clone();
            let selected = app.towns_view.selected_town == Some(i);
            if ui.selectable_label(selected, &name).clicked() {
                to_select = Some(i);
            }
        }
        if ui.small_button("+ Stadt").clicked() {
            add_town = true;
        }
    });

    if let Some(i) = to_select {
        app.towns_view.selected_town = Some(i);
    }
    if add_town {
        app.accounts[acc].towns.push(Town::default());
        app.towns_view.selected_town = Some(app.accounts[acc].towns.len() - 1);
    }

    ui.add_space(4.0);

    // ── Town form ─────────────────────────────────────────────────────────
    let settings = app.accounts[acc].settings;
    let theater_holz_town = app.accounts[acc].theater_holz_town;
    let theater_secondary_town = app.accounts[acc].theater_secondary_town;
    let mut capital_town = app.accounts[acc].capital_town;
    let mut to_remove: Option<usize> = None;
    if let Some(idx) = app.towns_view.selected_town {
        if idx < app.accounts[acc].towns.len() {
            let theater_holz = theater_holz_town == Some(idx);
            let theater_secondary = theater_secondary_town == Some(idx);
            if show_town_form(
                ui,
                &mut app.accounts[acc].towns[idx],
                &island_names,
                &island_resources,
                idx,
                settings,
                theater_holz,
                theater_secondary,
                &mut capital_town,
            ) {
                to_remove = Some(idx);
            }
        }
    }
    app.accounts[acc].capital_town = capital_town;

    if let Some(i) = to_remove {
        app.accounts[acc].towns.remove(i);
        // Clamp theater/capital indices if they pointed at or after the removed town
        let remaining = {
            let acc_data = &mut app.accounts[acc];
            for opt in [
                &mut acc_data.theater_holz_town,
                &mut acc_data.theater_secondary_town,
                &mut acc_data.capital_town,
            ] {
                if let Some(t) = *opt {
                    if t == i {
                        *opt = None;
                    } else if t > i {
                        *opt = Some(t - 1);
                    }
                }
            }
            acc_data.towns.len()
        };
        app.towns_view.selected_town = if remaining == 0 {
            None
        } else {
            Some(i.saturating_sub(1).min(remaining - 1))
        };
    }
}

/// One row in the per-resource settings grid.
fn settings_row(
    ui: &mut egui::Ui,
    label: &str,
    color: egui::Color32,
    premium: &mut bool,
    temp: &mut f64,
) {
    ui.colored_label(color, label);
    ui.checkbox(premium, "");
    let mut pct = *temp * 100.0;
    if ui
        .add(
            egui::DragValue::new(&mut pct)
                .range(0.0..=200.0)
                .speed(0.5)
                .suffix("%"),
        )
        .changed()
    {
        *temp = pct / 100.0;
    }
    ui.end_row();
}

/// Format a large number with thousands separators (German style, dot as separator).
/// e.g. 163502 -> "163.502"
fn fmt_big(n: u64) -> String {
    let s = n.to_string();
    let mut result = String::new();
    let chars: Vec<char> = s.chars().collect();
    let len = chars.len();
    for (i, c) in chars.iter().enumerate() {
        if i > 0 && (len - i) % 3 == 0 {
            result.push('.');
        }
        result.push(*c);
    }
    result
}

// Returns true if the town should be deleted.
fn show_town_form(
    ui: &mut egui::Ui,
    t: &mut Town,
    island_names: &[String],
    island_resources: &[IslandResource],
    row_idx: usize,
    settings: ProductionSettings,
    theater_holz: bool,
    theater_secondary: bool,
    capital_town: &mut Option<usize>,
) -> bool {
    let mut remove = false;
    let is_capital = *capital_town == Some(row_idx);
    let secondary_resource = t.island_id.and_then(|id| island_resources.get(id).copied());

    egui::Frame::group(ui.style()).show(ui, |ui| {
        // ── Basic info ────────────────────────────────────────────────────
        ui.horizontal(|ui| {
            let h = ui.spacing().interact_size.y;
            ui.add_sized([150.0, h], egui::TextEdit::singleline(&mut t.name));
            ui.separator();

            // Capital toggle
            if is_capital {
                ui.strong("Hauptstadt (Palast)");
            } else {
                if ui.small_button("Als Hauptstadt").clicked() {
                    *capital_town = Some(row_idx);
                }
            }
            ui.separator();

            ui.label("Insel:");
            let sel_rich = match t.island_id.and_then(|id| {
                Some((
                    island_names.get(id)?.as_str(),
                    island_resources.get(id)?.color(),
                ))
            }) {
                Some((name, color)) => egui::RichText::new(name).color(color),
                None => egui::RichText::new("—"),
            };
            egui::ComboBox::from_id_salt(("form_island", row_idx))
                .selected_text(sel_rich)
                .show_ui(ui, |ui| {
                    ui.selectable_value(&mut t.island_id, None, "—");
                    for (i, name) in island_names.iter().enumerate() {
                        let color = island_resources
                            .get(i)
                            .map(|r| r.color())
                            .unwrap_or(egui::Color32::WHITE);
                        ui.selectable_value(
                            &mut t.island_id,
                            Some(i),
                            egui::RichText::new(name.as_str()).color(color),
                        );
                    }
                });

            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                let del = egui::Button::new("✕ Stadt entfernen")
                    .fill(egui::Color32::from_rgb(100, 30, 30));
                if ui.add(del).clicked() {
                    remove = true;
                }
            });
        });

        // ── SHS / Palast + Lager ──────────────────────────────────────────
        ui.horizontal(|ui| {
            if is_capital {
                ui.colored_label(egui::Color32::GOLD, "Palast:");
                ui.add(level_drag(&mut t.palast_level, 50));
            } else {
                ui.label("SHS:");
                ui.add(level_drag(&mut t.stadthaltersitz, 50));
            }
            ui.separator();
            ui.label("Lager:");
            ui.add(level_drag(&mut t.warehouse_level, 50));
            let cap = tables::warehouse_capacity(t.warehouse_level);
            ui.label(format!("Kap: {}", fmt_big(cap)));
        });

        ui.separator();

        // ── Production ────────────────────────────────────────────────────
        ui.strong("Produktion");
        egui::Grid::new(("form_prod", row_idx))
            .min_col_width(0.0)
            .spacing([6.0, 4.0])
            .show(ui, |ui| {
                let capacity = tables::warehouse_capacity(t.warehouse_level);

                // Holz
                ui.colored_label(COLOR_HOLZ, "Holz");
                ui.label("Arbeiter:");
                ui.add(workers_drag(&mut t.holz_workers));
                ui.label("Forsthaus Stufe:");
                ui.add(building_drag(&mut t.forsthaus, 52));
                let prod = t.holz_production(&settings, theater_holz);
                ui.colored_label(COLOR_HOLZ, format!("= {prod:.1}/h"));
                // Stock
                ui.label("Bestand:");
                ui.add(
                    egui::DragValue::new(&mut t.holz_stock)
                        .range(0..=u64::MAX)
                        .speed(100.0),
                );
                // Overflow time
                let holz_overflow = if prod > 0.0 {
                    capacity.saturating_sub(t.holz_stock) as f64 / prod
                } else {
                    f64::INFINITY
                };
                ui.colored_label(
                    egui::Color32::GRAY,
                    format!("Voll in {}", tables::fmt_overflow(holz_overflow)),
                );
                ui.end_row();

                // Secondary resource
                match secondary_resource {
                    Some(res) => {
                        let color = res.color();
                        ui.colored_label(color, res.label());
                        ui.label("Arbeiter:");
                        ui.add(workers_drag(&mut t.secondary_workers));
                        ui.label(format!("{} Stufe:", res.town_production_building()));
                        ui.add(building_drag(t.secondary_building_level_mut(res), 50));
                        let prod = t.secondary_production(res, &settings, theater_secondary);
                        ui.colored_label(color, format!("= {prod:.1}/h"));
                        // Stock
                        ui.label("Bestand:");
                        ui.add(
                            egui::DragValue::new(&mut t.secondary_stock)
                                .range(0..=u64::MAX)
                                .speed(100.0),
                        );
                        // Overflow time
                        let sec_overflow = if prod > 0.0 {
                            capacity.saturating_sub(t.secondary_stock) as f64 / prod
                        } else {
                            f64::INFINITY
                        };
                        ui.colored_label(
                            egui::Color32::GRAY,
                            format!("Voll in {}", tables::fmt_overflow(sec_overflow)),
                        );
                    }
                    None => {
                        ui.colored_label(egui::Color32::GRAY, "(Insel wählen)");
                    }
                }
                ui.end_row();
            });

        ui.separator();

        // ── Consumption buildings ──────────────────────────────────────────
        ui.strong("Gebäude (Verbrauchsreduktion)");
        ui.horizontal(|ui| {
            let pairs: &mut [(&str, egui::Color32, &mut u32); 5] = &mut [
                ("Zimmerei", COLOR_HOLZ, &mut t.zimmerei),
                ("Kelterei", COLOR_WEIN, &mut t.kelterei),
                ("Architekturbüro", COLOR_MARMOR, &mut t.architekturburo),
                ("Optiker", COLOR_KRISTALL, &mut t.optiker),
                ("Feuerwerksplatz", COLOR_SCHWEFEL, &mut t.feuerwerksplatz),
            ];
            for (label, color, val) in pairs.iter_mut() {
                ui.horizontal(|ui| {
                    ui.colored_label(*color, *label);
                    ui.add(building_drag(val, 30));
                });
                ui.add_space(4.0);
            }
        });
    });

    remove
}

fn workers_drag(v: &mut u32) -> egui::DragValue<'_> {
    egui::DragValue::new(v).range(0..=9999).speed(1.0)
}

fn level_drag(v: &mut u32, max: u32) -> egui::DragValue<'_> {
    egui::DragValue::new(v).range(0..=max).speed(0.05)
}

fn building_drag(v: &mut u32, max: u32) -> egui::DragValue<'_> {
    egui::DragValue::new(v).range(0..=max).speed(0.05)
}

fn prod_label(ui: &mut egui::Ui, resource: &str, color: egui::Color32, val: f64) {
    ui.colored_label(color, format!("{resource}: {val:.0}/h"));
    ui.add_space(8.0);
}
