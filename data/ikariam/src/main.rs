mod app;
mod islands_view;
mod model;
mod optimize_view;
mod tables;
mod towns_view;

fn main() -> eframe::Result<()> {
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([1280.0, 800.0]),
        ..Default::default()
    };
    eframe::run_native(
        "Ikariam Planner",
        options,
        Box::new(|cc| {
            cc.egui_ctx.set_zoom_factor(1.8);
            let app: app::App = cc
                .storage
                .and_then(|s| eframe::get_value(s, eframe::APP_KEY))
                .unwrap_or_default();
            Ok(Box::new(app))
        }),
    )
}
