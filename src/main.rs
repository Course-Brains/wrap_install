use std::io::{Seek, SeekFrom, Write};

const TEMPLATE: &str = include_str!("template.sh");
static mut FILES: u32 = 0;


#[derive(serde::Deserialize)]
struct CargoManifest {
    package: CargoPackage
}
#[derive(serde::Deserialize)]
struct CargoPackage {
    name: String,
}
struct ScriptFile {
    header: Option<Header>,
    data: Vec<u8>
}
impl ScriptFile {
    fn new(path: impl AsRef<std::path::Path> + std::fmt::Debug) -> Self {
        println!("new file({:?})", path);
        unsafe { FILES += 1 }
        let mut out = ScriptFile {
            header: None,
            data: std::fs::read(&path).unwrap()
        };
        out.header = Some(Header::new(path, out.data.len() as u32));
        out
    }
    fn to_bytes(self) -> Vec<u8> {
        [self.header.unwrap().to_bytes(), self.data].concat()
    }
}
struct Header {
    path: String,
    data_len: u32,
}
impl Header {
    fn new(path: impl AsRef<std::path::Path>, data_len: u32) -> Self {
        Header {
            path: path.as_ref().to_str().unwrap().to_owned(),
            data_len
        }
    }
    fn to_bytes(&self) -> Vec<u8> {
        let mut output: Vec<u8> = Vec::new();
        output.extend_from_slice(&(self.path.len() as u32).to_be_bytes());
        output.extend_from_slice(self.path.as_bytes());
        output.extend_from_slice(&self.data_len.to_be_bytes());
        output
    }
}
#[derive(serde::Deserialize)]
struct TomlSettings {
    optimize: Option<bool>,
    bin_name: Option<String>,
    shell_name: Option<String>,
}
impl TomlSettings {
    fn get(path: impl AsRef<std::path::Path>) -> Result<TomlSettings, String> {
        match std::fs::read_to_string(path) {
            Ok(setting) => {
                match toml::from_str(&setting) {
                    Ok(toml) => Ok(toml),
                    Err(error) => Err("Invalid settings: ".to_string() + &error.to_string())
                }
            }
            Err(_) => {
                Ok(TomlSettings::default())
            }
        }
    }
}
impl Default for TomlSettings {
    fn default() -> TomlSettings {
        TomlSettings {
            optimize: Some(true),
            bin_name: None,
            shell_name: None,
        }
    }
}
struct Settings {
    optimize: bool,
    bin_name: Option<String>,
    shell_name: Option<String>,
}
impl Settings {
    fn get(path: impl AsRef<std::path::Path>) -> Settings {
        Settings::from(TomlSettings::get(path).unwrap())
    }
}
impl From<TomlSettings> for Settings {
    fn from(settings: TomlSettings) -> Settings {
        let optimize = match settings.optimize {
            Some(value) => value,
            None => true
        };
        Settings {
            optimize,
            bin_name: settings.bin_name,
            shell_name: settings.shell_name
        }
    }
}
fn main() {
    let cargo = std::fs::read_to_string("Cargo.toml").unwrap();
    let manifest: CargoManifest = toml::from_str(&cargo).unwrap();
    let settings = Settings::get("wrap_install.toml");
    let name = manifest.package.name;

    let mut shell_script = TEMPLATE.to_owned();

    // Insert things to the shell script starting from the back to prevent the chance
    // of false positives

    // Setting whether it should be optimized
    if settings.optimize {
        find_insert(&mut shell_script,
            "cargo build",
            " --release"
        ).unwrap();
    }
    
    // Putting in the int rust
    find_insert(&mut shell_script, "# Rust code here\necho '", include_str!("template.rs")).unwrap();

    // Section for putting the name of the project in the int rust file
    find_insert(&mut shell_script,
        "\n# Title here too\necho 'const TITLE: &str = \"../",
        &(name.to_owned()+".sh")
    ).unwrap();

    // Putting the cargo data in
    find_insert(&mut shell_script,
        "\n# Cargo.toml data goes here\necho \'",
        &cargo
    ).unwrap();

    // Giving the name of the bin to the shell script
    match settings.bin_name {
        Some(bin_name) => {
            find_insert(&mut shell_script,
                "\n# Title goes here\ntitle=\"",
                &bin_name
            ).unwrap();
        }
        None => {
            find_insert(&mut shell_script,
                "\n# Title goes here\ntitle=\"",
                &name
            ).unwrap();
        }
    }

    // Shell script file creation
    let path_name: String;
    match settings.shell_name {
        Some(new_name) => {
            path_name = new_name+".sh"
        }
        None => {
            path_name = name+".sh"
        }
    }
    std::fs::write(&path_name, shell_script).unwrap();
    // Shell script file insertion
    let mut file = std::fs::OpenOptions::new().append(true).write(true).truncate(false).open(path_name).unwrap();
    let len = file.metadata().unwrap().len();
    file.seek(SeekFrom::End(0)).unwrap();
    get_files("src", &mut file);
    file.write_all(&len.to_be_bytes()).unwrap();
    println!("number of files: {}", unsafe { FILES });
    file.write_all(unsafe { &FILES.to_be_bytes() }).unwrap();
}
fn get_files(path: impl AsRef<std::path::Path>, file: &mut std::fs::File) {
    for item in std::fs::read_dir("src").unwrap() {
        if let Ok(item) = item {
            if let Ok(metadata) = item.metadata() {
                if metadata.is_dir() {
                    get_files(path.as_ref().join(item.file_name()), file)
                }
                else if metadata.is_file() {
                    file.write_all(
                        &ScriptFile::new(path.as_ref().join(item.file_name())).to_bytes()
                    ).unwrap();
                    file.seek(SeekFrom::End(-1)).unwrap();
                }
            }
        }
    }
}
fn find_insert(shell_script: &mut String, find: &str, insert: &str) -> Option<()> {
    let index = shell_script.find(find)?;
    shell_script.insert_str(index+find.len(), insert);
    Some(())
}