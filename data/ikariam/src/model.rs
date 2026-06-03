use egui;

pub const COLOR_HOLZ: egui::Color32 = egui::Color32::from_rgb(180, 120, 60);
pub const COLOR_WEIN: egui::Color32 = egui::Color32::from_rgb(180, 80, 160);
pub const COLOR_MARMOR: egui::Color32 = egui::Color32::from_rgb(130, 160, 200);
pub const COLOR_KRISTALL: egui::Color32 = egui::Color32::from_rgb(100, 200, 220);
pub const COLOR_SCHWEFEL: egui::Color32 = egui::Color32::from_rgb(200, 200, 80);

#[derive(Clone, Copy, PartialEq, Default, serde::Serialize, serde::Deserialize)]
pub enum IslandResource {
    #[default]
    Wein,
    Marmor,
    Kristall,
    Schwefel,
}

impl IslandResource {
    pub fn label(self) -> &'static str {
        match self {
            Self::Wein => "Wein",
            Self::Marmor => "Marmor",
            Self::Kristall => "Kristall",
            Self::Schwefel => "Schwefel",
        }
    }

    pub fn building(self) -> &'static str {
        match self {
            Self::Wein => "Weinberg",
            Self::Marmor => "Steinbruch",
            Self::Kristall => "Kristallmine",
            Self::Schwefel => "Schwefelgrube",
        }
    }

    pub fn town_production_building(self) -> &'static str {
        match self {
            Self::Wein => "Winzerei",
            Self::Marmor => "Steinmetz",
            Self::Kristall => "Glasbläserei",
            Self::Schwefel => "Alchemistenturm",
        }
    }

    pub fn color(self) -> egui::Color32 {
        match self {
            Self::Wein => COLOR_WEIN,
            Self::Marmor => COLOR_MARMOR,
            Self::Kristall => COLOR_KRISTALL,
            Self::Schwefel => COLOR_SCHWEFEL,
        }
    }
}

#[derive(Clone, Copy, Default, serde::Serialize, serde::Deserialize)]
pub struct ProductionSettings {
    #[serde(default)]
    pub premium_holz: bool,
    #[serde(default)]
    pub premium_wein: bool,
    #[serde(default)]
    pub premium_marmor: bool,
    #[serde(default)]
    pub premium_kristall: bool,
    #[serde(default)]
    pub premium_schwefel: bool,
    #[serde(default)]
    pub temp_holz: f64,
    #[serde(default)]
    pub temp_wein: f64,
    #[serde(default)]
    pub temp_marmor: f64,
    #[serde(default)]
    pub temp_kristall: f64,
    #[serde(default)]
    pub temp_schwefel: f64,
}

impl ProductionSettings {
    pub fn premium_for(&self, resource: IslandResource) -> bool {
        match resource {
            IslandResource::Wein => self.premium_wein,
            IslandResource::Marmor => self.premium_marmor,
            IslandResource::Kristall => self.premium_kristall,
            IslandResource::Schwefel => self.premium_schwefel,
        }
    }

    pub fn temp_for(&self, resource: IslandResource) -> f64 {
        match resource {
            IslandResource::Wein => self.temp_wein,
            IslandResource::Marmor => self.temp_marmor,
            IslandResource::Kristall => self.temp_kristall,
            IslandResource::Schwefel => self.temp_schwefel,
        }
    }
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub struct Island {
    #[serde(default)]
    pub name: String,
    #[serde(default)]
    pub resource: IslandResource,
    #[serde(default)]
    pub sagewerk: u32,
    #[serde(default)]
    pub resource_level: u32,
}

impl Default for Island {
    fn default() -> Self {
        Self {
            name: "Neue Insel".to_string(),
            resource: IslandResource::default(),
            sagewerk: 0,
            resource_level: 0,
        }
    }
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub struct Town {
    #[serde(default)]
    pub name: String,
    #[serde(default)]
    pub island_id: Option<usize>,
    #[serde(default)]
    pub stadthaltersitz: u32,
    #[serde(default)]
    pub palast_level: u32,
    #[serde(default)]
    pub warehouse_level: u32,
    #[serde(default)]
    pub holz_workers: u32,
    #[serde(default)]
    pub secondary_workers: u32,
    #[serde(default)]
    pub forsthaus: u32,
    #[serde(default)]
    pub winzerei: u32,
    #[serde(default)]
    pub steinmetz: u32,
    #[serde(default)]
    pub glasblaeserei: u32,
    #[serde(default)]
    pub alchemistenturm: u32,
    #[serde(default)]
    pub zimmerei: u32,
    #[serde(default)]
    pub kelterei: u32,
    #[serde(default)]
    pub architekturburo: u32,
    #[serde(default)]
    pub optiker: u32,
    #[serde(default)]
    pub feuerwerksplatz: u32,
    #[serde(default)]
    pub holz_stock: u64,
    #[serde(default)]
    pub secondary_stock: u64,
}

impl Town {
    fn production_multiplier(&self, building_level: u32, theater: bool, premium: bool, temp_bonus: f64) -> f64 {
        let premium_bonus = if premium { 0.20 } else { 0.0 };
        let theater_bonus = if theater { 0.20 } else { 0.0 };
        let building_bonus = building_level as f64 * 0.02;
        1.0 + premium_bonus + theater_bonus + temp_bonus + building_bonus
    }

    pub fn holz_production(&self, settings: &ProductionSettings, theater: bool) -> f64 {
        let mult = self.production_multiplier(self.forsthaus, theater, settings.premium_holz, settings.temp_holz);
        self.holz_workers as f64 * mult
    }

    pub fn secondary_production(&self, resource: IslandResource, settings: &ProductionSettings, theater: bool) -> f64 {
        let level = self.secondary_building_level(resource);
        let mult = self.production_multiplier(level, theater, settings.premium_for(resource), settings.temp_for(resource));
        self.secondary_workers as f64 * mult
    }

    pub fn secondary_building_level(&self, resource: IslandResource) -> u32 {
        match resource {
            IslandResource::Wein => self.winzerei,
            IslandResource::Marmor => self.steinmetz,
            IslandResource::Kristall => self.glasblaeserei,
            IslandResource::Schwefel => self.alchemistenturm,
        }
    }

    pub fn secondary_building_level_mut(&mut self, resource: IslandResource) -> &mut u32 {
        match resource {
            IslandResource::Wein => &mut self.winzerei,
            IslandResource::Marmor => &mut self.steinmetz,
            IslandResource::Kristall => &mut self.glasblaeserei,
            IslandResource::Schwefel => &mut self.alchemistenturm,
        }
    }
}

impl Default for Town {
    fn default() -> Self {
        Self {
            name: "Neue Stadt".to_string(),
            island_id: None,
            stadthaltersitz: 1,
            palast_level: 0,
            warehouse_level: 5,
            holz_workers: 0,
            secondary_workers: 0,
            forsthaus: 0,
            winzerei: 0,
            steinmetz: 0,
            glasblaeserei: 0,
            alchemistenturm: 0,
            zimmerei: 0,
            kelterei: 0,
            architekturburo: 0,
            optiker: 0,
            feuerwerksplatz: 0,
            holz_stock: 0,
            secondary_stock: 0,
        }
    }
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub struct Account {
    #[serde(default)]
    pub name: String,
    #[serde(default)]
    pub towns: Vec<Town>,
    #[serde(default)]
    pub islands: Vec<Island>,
    #[serde(default)]
    pub settings: ProductionSettings,
    #[serde(default)]
    pub theater_holz_town: Option<usize>,
    #[serde(default)]
    pub theater_secondary_town: Option<usize>,
    #[serde(default)]
    pub capital_town: Option<usize>,
}

impl Default for Account {
    fn default() -> Self {
        Self {
            name: "Neuer Account".to_string(),
            towns: vec![],
            islands: vec![],
            settings: ProductionSettings::default(),
            theater_holz_town: None,
            theater_secondary_town: None,
            capital_town: None,
        }
    }
}

pub fn demo_account() -> Account {
    Account {
        name: "Spieler1".to_string(),
        settings: ProductionSettings::default(),
        theater_holz_town: None,
        theater_secondary_town: None,
        capital_town: Some(0),
        islands: vec![
            Island {
                name: "Aegäis".to_string(),
                resource: IslandResource::Wein,
                sagewerk: 5,
                resource_level: 4,
            },
            Island {
                name: "Kreta".to_string(),
                resource: IslandResource::Marmor,
                sagewerk: 4,
                resource_level: 4,
            },
            Island {
                name: "Ionien".to_string(),
                resource: IslandResource::Kristall,
                sagewerk: 3,
                resource_level: 3,
            },
        ],
        towns: vec![
            Town {
                name: "Athen".to_string(),
                island_id: Some(0),
                stadthaltersitz: 3,
                palast_level: 0,
                warehouse_level: 12,
                holz_workers: 220,
                secondary_workers: 80,
                forsthaus: 3,
                winzerei: 2,
                steinmetz: 0,
                glasblaeserei: 0,
                alchemistenturm: 0,
                zimmerei: 5,
                kelterei: 3,
                architekturburo: 0,
                optiker: 0,
                feuerwerksplatz: 0,
                holz_stock: 5000,
                secondary_stock: 2000,
            },
            Town {
                name: "Peloponnes".to_string(),
                island_id: Some(1),
                stadthaltersitz: 3,
                palast_level: 0,
                warehouse_level: 10,
                holz_workers: 170,
                secondary_workers: 98,
                forsthaus: 2,
                winzerei: 0,
                steinmetz: 3,
                glasblaeserei: 0,
                alchemistenturm: 0,
                zimmerei: 3,
                kelterei: 0,
                architekturburo: 4,
                optiker: 0,
                feuerwerksplatz: 0,
                holz_stock: 5000,
                secondary_stock: 2000,
            },
            Town {
                name: "Sparta".to_string(),
                island_id: Some(2),
                stadthaltersitz: 3,
                palast_level: 0,
                warehouse_level: 8,
                holz_workers: 115,
                secondary_workers: 42,
                forsthaus: 2,
                winzerei: 0,
                steinmetz: 0,
                glasblaeserei: 2,
                alchemistenturm: 0,
                zimmerei: 2,
                kelterei: 0,
                architekturburo: 0,
                optiker: 3,
                feuerwerksplatz: 0,
                holz_stock: 5000,
                secondary_stock: 2000,
            },
        ],
    }
}
