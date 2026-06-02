use crate::model::{demo_account, Account};
use egui;

#[derive(Clone, Copy, PartialEq, serde::Serialize, serde::Deserialize)]
pub enum View {
    Towns,
    Islands,
    Optimize,
}

#[derive(serde::Serialize, serde::Deserialize)]
pub struct App {
    pub accounts: Vec<Account>,
    pub current_account: usize,
    pub view: View,
    pub optimize: crate::optimize_view::OptimizeState,
    pub towns_view: crate::towns_view::TownsViewState,
    #[serde(skip)]
    confirm_delete_account: bool,
}

impl Default for App {
    fn default() -> Self {
        Self {
            accounts: vec![demo_account()],
            current_account: 0,
            view: View::Towns,
            optimize: Default::default(),
            towns_view: Default::default(),
            confirm_delete_account: false,
        }
    }
}

impl eframe::App for App {
    fn save(&mut self, storage: &mut dyn eframe::Storage) {
        eframe::set_value(storage, eframe::APP_KEY, self);
    }

    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::TopBottomPanel::top("toolbar").show(ctx, |ui| {
            ui.horizontal(|ui| {
                ui.heading("Ikariam Planner");
                ui.separator();

                let names: Vec<String> =
                    self.accounts.iter().map(|a| a.name.clone()).collect();
                ui.label("Account");
                egui::ComboBox::from_id_salt("account_combo")
                    .selected_text(
                        self.accounts
                            .get(self.current_account)
                            .map(|a| a.name.as_str())
                            .unwrap_or("—"),
                    )
                    .show_ui(ui, |ui| {
                        for (i, name) in names.iter().enumerate() {
                            ui.selectable_value(&mut self.current_account, i, name);
                        }
                    });

                if let Some(acc) = self.accounts.get_mut(self.current_account) {
                    ui.add(
                        egui::TextEdit::singleline(&mut acc.name)
                            .desired_width(120.0)
                            .hint_text("Account-Name"),
                    );
                }

                if ui.button("+ Account").clicked() {
                    self.accounts.push(Account::default());
                    self.current_account = self.accounts.len() - 1;
                }

                if self.accounts.len() > 1 {
                    let del_btn = egui::Button::new("✕")
                        .fill(egui::Color32::from_rgb(120, 35, 35));
                    if ui.add(del_btn).on_hover_text("Account löschen").clicked() {
                        self.confirm_delete_account = true;
                    }
                }

                ui.separator();

                ui.selectable_value(&mut self.view, View::Towns, "Städte");
                ui.selectable_value(&mut self.view, View::Islands, "Inseln");
                ui.selectable_value(&mut self.view, View::Optimize, "Optimierung");
            });
        });

        if self.confirm_delete_account {
            egui::Window::new("Account löschen?")
                .collapsible(false)
                .resizable(false)
                .anchor(egui::Align2::CENTER_CENTER, egui::vec2(0.0, 0.0))
                .show(ctx, |ui| {
                    let name = self.accounts[self.current_account].name.clone();
                    ui.label(format!("Account \"{name}\" wirklich löschen?"));
                    ui.add_space(8.0);
                    ui.horizontal(|ui| {
                        if ui.button("Abbrechen").clicked() {
                            self.confirm_delete_account = false;
                        }
                        let del_btn = egui::Button::new("Löschen")
                            .fill(egui::Color32::from_rgb(120, 35, 35));
                        if ui.add(del_btn).clicked() {
                            self.accounts.remove(self.current_account);
                            self.current_account =
                                self.current_account.saturating_sub(1);
                            self.confirm_delete_account = false;
                        }
                    });
                });
        }

        egui::CentralPanel::default().show(ctx, |ui| {
            if self.accounts.is_empty() {
                ui.centered_and_justified(|ui| {
                    ui.label("Kein Account. Bitte oben einen anlegen.");
                });
                return;
            }
            match self.view {
                View::Towns => crate::towns_view::show(self, ui),
                View::Islands => crate::islands_view::show(self, ui),
                View::Optimize => crate::optimize_view::show(self, ui),
            }
        });
    }
}
