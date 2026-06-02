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

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub struct Island {
    pub name: String,
    pub resource: IslandResource,
    pub sagewerk: u32,
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
    pub name: String,
    pub island_id: Option<usize>,
    pub stadthaltersitz: u32,
    pub warehouse_level: u32,
    // Workers assigned to each resource
    pub holz_workers: u32,
    pub secondary_workers: u32,
    // Production buildings (+2% output per level)
    pub forsthaus: u32,
    pub winzerei: u32,
    pub steinmetz: u32,
    pub glasblaeserei: u32,
    pub alchemistenturm: u32,
    // Consumption buildings (reduce resource usage)
    pub zimmerei: u32,
    pub kelterei: u32,
    pub architekturburo: u32,
    pub optiker: u32,
    pub feuerwerksplatz: u32,
}

impl Town {
    pub fn holz_production(&self) -> f64 {
        self.holz_workers as f64 * (1.0 + 0.02 * self.forsthaus as f64)
    }

    pub fn secondary_production(&self, resource: IslandResource) -> f64 {
        self.secondary_workers as f64
            * (1.0 + 0.02 * self.secondary_building_level(resource) as f64)
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
        }
    }
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub struct Account {
    pub name: String,
    pub towns: Vec<Town>,
    pub islands: Vec<Island>,
}

impl Default for Account {
    fn default() -> Self {
        Self {
            name: "Neuer Account".to_string(),
            towns: vec![],
            islands: vec![],
        }
    }
}

pub fn demo_account() -> Account {
    Account {
        name: "Spieler1".to_string(),
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
            },
            Town {
                name: "Peloponnes".to_string(),
                island_id: Some(1),
                stadthaltersitz: 3,
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
            },
            Town {
                name: "Sparta".to_string(),
                island_id: Some(2),
                stadthaltersitz: 3,
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
            },
        ],
    }
}
