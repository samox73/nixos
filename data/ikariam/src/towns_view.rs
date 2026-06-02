use crate::app::App;
use crate::model::{
    IslandResource, Town, COLOR_HOLZ, COLOR_KRISTALL, COLOR_MARMOR, COLOR_SCHWEFEL, COLOR_WEIN,
};
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

    // ── Totals bar ────────────────────────────────────────────────────────
    {
        let towns = &app.accounts[acc].towns;
        let mut total_holz = 0.0_f64;
        let mut totals = [0.0_f64; 4]; // indexed by IslandResource discriminant
        for t in towns {
            total_holz += t.holz_production();
            if let Some(res) = t.island_id.and_then(|id| island_resources.get(id).copied()) {
                totals[res as usize] += t.secondary_production(res);
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

    // ── Town tab bar ──────────────────────────────────────────────────────
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
    let mut to_remove: Option<usize> = None;
    if let Some(idx) = app.towns_view.selected_town {
        if idx < app.accounts[acc].towns.len() {
            if show_town_form(
                ui,
                &mut app.accounts[acc].towns[idx],
                &island_names,
                &island_resources,
                idx,
            ) {
                to_remove = Some(idx);
            }
        }
    }

    if let Some(i) = to_remove {
        app.accounts[acc].towns.remove(i);
        let remaining = app.accounts[acc].towns.len();
        app.towns_view.selected_town = if remaining == 0 {
            None
        } else {
            Some(i.saturating_sub(1).min(remaining - 1))
        };
    }
}

// Returns true if the town should be deleted.
fn show_town_form(
    ui: &mut egui::Ui,
    t: &mut Town,
    island_names: &[String],
    island_resources: &[IslandResource],
    row_idx: usize,
) -> bool {
    let mut remove = false;
    let secondary_resource = t.island_id.and_then(|id| island_resources.get(id).copied());

    egui::Frame::group(ui.style()).show(ui, |ui| {
        // ── Basic info ────────────────────────────────────────────────────
        ui.horizontal(|ui| {
            let h = ui.spacing().interact_size.y;
            ui.add_sized([150.0, h], egui::TextEdit::singleline(&mut t.name));
            ui.separator();
            ui.label("Insel:");
            let sel_text = t
                .island_id
                .and_then(|id| island_names.get(id))
                .map(String::as_str)
                .unwrap_or("—");
            egui::ComboBox::from_id_salt(("form_island", row_idx))
                .selected_text(sel_text)
                .show_ui(ui, |ui| {
                    ui.selectable_value(&mut t.island_id, None, "—");
                    for (i, name) in island_names.iter().enumerate() {
                        ui.selectable_value(&mut t.island_id, Some(i), name.as_str());
                    }
                });
            ui.separator();
            ui.label("SHS:");
            ui.add(level_drag(&mut t.stadthaltersitz, 50));
            ui.separator();
            ui.label("Lager:");
            ui.add(level_drag(&mut t.warehouse_level, 50));
            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                let del = egui::Button::new("✕ Stadt entfernen")
                    .fill(egui::Color32::from_rgb(100, 30, 30));
                if ui.add(del).clicked() {
                    remove = true;
                }
            });
        });

        ui.separator();

        // ── Production ────────────────────────────────────────────────────
        ui.strong("Produktion");
        egui::Grid::new(("form_prod", row_idx))
            .min_col_width(0.0)
            .spacing([6.0, 4.0])
            .show(ui, |ui| {
                // Holz
                ui.colored_label(COLOR_HOLZ, "Holz");
                ui.label("Arbeiter:");
                ui.add(workers_drag(&mut t.holz_workers));
                ui.label("Forsthaus Stufe:");
                ui.add(building_drag(&mut t.forsthaus, 52));
                let prod = t.holz_production();
                ui.colored_label(COLOR_HOLZ, format!("= {prod:.1}/h"));
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
                        let prod = t.secondary_production(res);
                        ui.colored_label(color, format!("= {prod:.1}/h"));
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
