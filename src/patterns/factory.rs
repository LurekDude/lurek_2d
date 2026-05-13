use std::collections::HashSet;
#[derive(Debug, Default)]
pub struct Factory {
    pub types: HashSet<String>,
    pub aliases: std::collections::HashMap<String, String>,
}
impl Factory {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn register(&mut self, name: &str) {
        self.types.insert(name.to_string());
    }
    pub fn unregister(&mut self, name: &str) -> bool {
        self.aliases.retain(|_, v| v != name);
        self.types.remove(name)
    }
    pub fn has(&self, name: &str) -> bool {
        self.types.contains(name) || self.aliases.contains_key(name)
    }
    pub fn resolve<'a>(&'a self, name: &'a str) -> &'a str {
        self.aliases.get(name).map(String::as_str).unwrap_or(name)
    }
    pub fn add_alias(&mut self, alias: &str, canonical: &str) {
        self.aliases
            .insert(alias.to_string(), canonical.to_string());
    }
    pub fn type_names(&self) -> Vec<&str> {
        let mut names: Vec<&str> = self.types.iter().map(String::as_str).collect();
        names.sort();
        names
    }
    pub fn clear(&mut self) {
        self.types.clear();
        self.aliases.clear();
    }
}
