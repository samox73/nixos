use crate::app::App;
use crate::model::{Island, IslandResource};
use egui;

pub fn show(app: &mut App, ui: &mut egui::Ui) {
    let acc = app.current_account;

    let name_w = {
        let fid = egui::TextStyle::Body.resolve(ui.style());
        let pad = 16.0_f32;
        let measure = |s: &str| {
            ui.fonts(|f| {
                f.layout_no_wrap(s.to_owned(), fid.clone(), egui::Color32::WHITE)
                    .size()
                    .x
            })
        };
        app.accounts[acc]
            .islands
            .iter()
            .map(|isl| measure(&isl.name))
            .fold(measure("Name"), f32::max)
            + pad
    };

    let mut to_remove: Option<usize> = None;

    egui::ScrollArea::horizontal().show(ui, |ui| {
        egui::Grid::new("islands_grid")
            .striped(true)
            .min_col_width(0.0)
            .spacing([6.0, 4.0])
            .show(ui, |ui| {
                // header
                ui.strong("Name");
                ui.strong("Sägewerk");
                ui.strong("Ressource");
                ui.strong("Stufe");
                ui.label("");
                ui.end_row();

                let n = app.accounts[acc].islands.len();
                for i in 0..n {
                    let h = ui.spacing().interact_size.y;
                    let island = &mut app.accounts[acc].islands[i];

                    ui.add_sized([name_w, h], egui::TextEdit::singleline(&mut island.name));
                    ui.add(level_drag(&mut island.sagewerk, 60));

                    egui::ComboBox::from_id_salt(("island_res", i))
                        .selected_text(
                            egui::RichText::new(island.resource.label())
                                .color(island.resource.color()),
                        )
                        .show_ui(ui, |ui| {
                            for res in [
                                IslandResource::Wein,
                                IslandResource::Marmor,
                                IslandResource::Kristall,
                                IslandResource::Schwefel,
                            ] {
                                ui.selectable_value(
                                    &mut island.resource,
                                    res,
                                    egui::RichText::new(res.label()).color(res.color()),
                                );
                            }
                        });

                    let bldg = island.resource.building();
                    ui.add(level_drag(&mut island.resource_level, 60))
                        .on_hover_text(bldg);

                    if ui
                        .small_button("X")
                        .on_hover_text("Insel entfernen")
                        .clicked()
                    {
                        to_remove = Some(i);
                    }
                    ui.end_row();
                }
            });
    });

    if let Some(idx) = to_remove {
        // Fix up town island_ids so they stay consistent
        for town in &mut app.accounts[acc].towns {
            match town.island_id {
                Some(id) if id == idx => town.island_id = None,
                Some(id) if id > idx => town.island_id = Some(id - 1),
                _ => {}
            }
        }
        app.accounts[acc].islands.remove(idx);
    }

    ui.add_space(4.0);
    if ui.button("+ Insel hinzufügen").clicked() {
        app.accounts[acc].islands.push(Island::default());
    }
}

fn level_drag(v: &mut u32, max: u32) -> egui::DragValue<'_> {
    egui::DragValue::new(v).range(0..=max).speed(0.05)
}
