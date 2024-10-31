use std::io::{Seek, SeekFrom, Write};

const TEMPLATE: &str = include_str!("template.sh");
const HELP: &str = include_str!("help.txt");

static mut FILES: u32 = 0;
static mut MODE: Mode = Mode::Normal;


macro_rules! verbose {
    ($($arg:tt)*) => {
        unsafe {
            if let Mode::Verbose = MODE {
                println!($($arg)*)
            }
        }
    }
}
macro_rules! quiet {
    ($($arg:tt)*) => {
        unsafe {
            if let Mode::Quiet = MODE {}
            else {
                println!($($arg)*)
            }
        }
    }
}

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
        quiet!("file({:?})", path);
        verbose!("incrementing number of files by 1");
        unsafe { FILES += 1 }
        verbose!("numbre of files: {FILES}\ncreating data/header\nreading file for data");
        let mut out = ScriptFile {
            header: None,
            data: std::fs::read(&path).unwrap()
        };
        verbose!("creating header");
        out.header = Some(Header::new(path, out.data.len() as u32));
        out
    }
    fn to_bytes(self) -> Vec<u8> {
        verbose!("converting file data to raw bytes");
        [self.header.unwrap().to_bytes(), self.data].concat()
    }
}
struct Header {
    path: String,
    data_len: u32,
}
impl Header {
    fn new(path: impl AsRef<std::path::Path> + std::fmt::Debug, data_len: u32) -> Self {
        verbose!("creating header for {data_len} length data at {:?}", path);
        Header {
            path: path.as_ref().to_str().unwrap().to_owned(),
            data_len
        }
    }
    fn to_bytes(&self) -> Vec<u8> {
        verbose!("converting header to raw bytes");
        let mut output: Vec<u8> = Vec::new();
        verbose!("adding path length to raw bytes");
        output.extend_from_slice(&(self.path.len() as u32).to_be_bytes());
        verbose!("adding path to raw bytes");
        output.extend_from_slice(self.path.as_bytes());
        verbose!("adding data length to raw bytes");
        output.extend_from_slice(&self.data_len.to_be_bytes());
        verbose!("done creating raw bytes from header");
        output
    }
}
#[derive(serde::Deserialize)]
struct TomlSettings {
    optimize: Option<bool>,
    bin_name: Option<String>,
    shell_name: Option<String>,
    mode: Option<String>,
    sh_dir: Option<String>,
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
            mode: None,
            sh_dir: None,
        }
    }
}
struct Settings {
    optimize: bool,
    bin_name: Option<String>,
    shell_name: Option<String>,
    mode: Mode,
    sh_dir: Option<String>,
}
impl Settings {
    fn get(path: impl AsRef<std::path::Path>) -> Settings {
        Settings::from(TomlSettings::get(path).unwrap())
    }
    fn bin_arg(&mut self, arg: Option<String>) {
        let item = arg.expect("Expected an argument after '--bin-name'");
        verbose!("argument value: {item}");
        if item == "default" {
            verbose!("overriding to default");
            self.bin_name = None;
            return
        }
        verbose!("changing bin name to {item}");
        self.bin_name = Some(item);
    }
    fn shell_arg(&mut self, arg: Option<String>) {
        let item = arg.expect("Expected an argument after '--shell-name'");
        verbose!("argument value: {item}");
        if item == "default" {
            verbose!("overriding to default");
            self.shell_name = None;
            return
        }
        verbose!("changing bin name to {item}");
        self.shell_name = Some(item);
    }
}
impl From<TomlSettings> for Settings {
    fn from(settings: TomlSettings) -> Settings {
        let mode = match settings.mode {
            Some(mode) => {
                Mode::try_from(mode).expect("Invalid mode, valid values are: verbose, quiet, and normal")
            }
            None => Mode::Normal
        };
        Settings {
            optimize: settings.optimize.unwrap_or(true),
            bin_name: settings.bin_name,
            shell_name: settings.shell_name,
            mode,
            sh_dir: settings.sh_dir,
        }
    }
}
impl std::fmt::Display for Settings {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        writeln!(f, "optimize: {}", self.optimize)?;
        match &self.bin_name {
            Some(name) => writeln!(f, "bin name: {name}")?,
            None => writeln!(f, "bin name: default")?
        }
        match &self.shell_name {
            Some(name) => writeln!(f, "shell name: {name}")?,
            None => writeln!(f, "shell name: default")?
        }
        writeln!(f, "mode: {}", self.mode)?;
        writeln!(f, "shell script out path: {:?}", self.sh_dir)
    }
}
#[derive(PartialEq, Clone, Copy)]
enum Mode {
    Normal,
    Quiet,
    Verbose
}
impl TryFrom<String> for Mode {
    type Error = ();
    fn try_from(value: String) -> Result<Self, Self::Error> {
        match value.to_ascii_lowercase().as_str() {
            "verbose" => Ok(Mode::Verbose),
            "quiet" => Ok(Mode::Quiet),
            "normal" => Ok(Mode::Normal),
            _ => Err(())
        }
    }
}
impl std::fmt::Display for Mode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Mode::Normal => write!(f, "normal"),
            Mode::Quiet => write!(f, "quiet"),
            Mode::Verbose => write!(f, "verbose"),
        }
    }
}
fn main() {
    let mut settings = Settings::get("wrap_install.toml");
    verbose!("Settings from file: {settings}");
    unsafe { MODE = settings.mode }
    // Changing settings based on arguments
    let mut args = std::env::args();
    while let Some(arg) = args.next() {
        verbose!("argument: {arg}");
        match arg.as_str() {
            "--noraml" => settings.mode = Mode::Normal,
            "--quiet" => settings.mode = Mode::Quiet,
            "--verbose" => settings.mode = Mode::Verbose,
            "--unoptimize" => settings.optimize = false,
            "--optimize" => settings.optimize = true,
            "--sh-dir" => settings.sh_dir = Some(args.next().expect("Expected value after '--sh-dir'")),
            "--bin-name" => settings.bin_arg(args.next()),
            "--shell-name" => settings.shell_arg(args.next()),
            "help" => {
                println!("{HELP}");
                return
            },
            _ => {}
        }
    }
    unsafe { MODE = settings.mode }
    quiet!("Running with settings:\n{settings}");
    let mut toml = std::fs::read_to_string("Cargo.toml").unwrap();
    let manifest: CargoManifest = toml::from_str(&toml).unwrap();
    let name = manifest.package.name;
    let lock = std::fs::read_to_string("Cargo.lock").unwrap();
    verbose!("package name: {name}\nout directory: {:?}", settings.sh_dir);

    verbose!("creating shell script string");
    let mut shell_script = TEMPLATE.to_owned();

    // Insert things to the shell script starting from the back to prevent the chance
    // of false positives

    // Giving the name of the bin to the shell script
    verbose!("changing bin name according to settings");
    let bin_name = match settings.bin_name {
        Some(ref name) => {verbose!("bin name: {name}"); name }
        None => {verbose!("bin name: default({name})"); &name }
    };
    verbose!("changing shell script string to have bin name: {bin_name}");
    find_insert(&mut shell_script, "mv project/target/release/", bin_name);

    // Changes for unoptimized
    verbose!("changing optimization according to settings");
    if !settings.optimize {
        // Replacing the directory to get the binary from (release => debug)
        verbose!("unoptimized\nchanging mv directory");
        let mut index = shell_script.find("mv project/target/").unwrap()+"mv project/target/".len();
        for _ in 0.."release".len() {
            shell_script.remove(index);
        }
        shell_script.insert_str(index, "debug");
        // Changing cargo build --release to cargo build
        verbose!("changing cargo build --release to not have release");
        index = shell_script.find("cargo build").unwrap()+"cargo build".len();
        for _ in 0.." --release".len() {
            shell_script.remove(index);
        }
    }
    else {
        verbose!("optimized: no change needed")
    }
    
    // Putting in the int rust
    verbose!("inserting extractor => shell script string");
    find_insert(&mut shell_script, "# Rust code here\necho '", include_str!("template.rs")).unwrap();

    // Section for putting the name of the project in the int rust file
    verbose!("inserting project name => shell script string");
    find_insert(&mut shell_script,
        "\n# Title here too\necho 'const TITLE: &str = \"../",
        &(name.to_owned()+".sh")
    ).unwrap();

    // changing the toml file so that the bin name is correct
    verbose!("setting bin name in cargo string");
    if let Some(new_name) = &settings.bin_name {
        verbose!("bin name changing to: {new_name}");
        let mut table: toml::Table = toml.parse().unwrap();
        if let toml::Value::Table(package) = table.get_mut("package").unwrap() {
            if let toml::Value::String(name) = package.get_mut("name").unwrap() {
                *name = new_name.clone()
            }
        }
        toml = toml::to_string(&table).unwrap()
    }
    else {
        verbose!("no change needed")
    }
    
    // Putting the Cargo.lock data in
    verbose!("Inserting Cargo.lock data => shell script string");
    find_insert(&mut shell_script,
        "\n# Cargo.lock data goes here\necho \'",
        &lock    
    ).unwrap();

    // Putting the Cargo.toml data in
    verbose!("inserting Cargo.toml data => shell script string");
    find_insert(&mut shell_script,
        "\n# Cargo.toml data goes here\necho \'",
        &toml
    ).unwrap();

    // Shell script file creation
    verbose!("defining shell script path name from settings if needed");
    let sh_dir = settings.sh_dir.unwrap_or("".to_string());
    let path_name: String;
    match settings.shell_name {
        Some(new_name) => {
            verbose!("overriding shell script path name to: {new_name}");
            path_name = sh_dir+&new_name+".sh"
        }
        None => {
            verbose!("shell script path name is default({name})");
            path_name = sh_dir+&name+".sh"
        }
    }
    verbose!("creating shell script from shell script string");
    std::fs::write(&path_name, shell_script).unwrap();
    // Shell script file insertion
    verbose!("opening shell script({path_name}) to append raw file data");
    let mut file = std::fs::OpenOptions::new().append(true).write(true).truncate(false).open(path_name).unwrap();
    verbose!("getting current length of file for start position of data read");
    let len = file.metadata().unwrap().len();
    verbose!("start position is {len}\nseeking to end of file");
    file.seek(SeekFrom::End(0)).unwrap();
    verbose!("appending files in src to shell script");
    get_files("src", &mut file);
    verbose!("appending start position to shell script");
    file.write_all(&len.to_be_bytes()).unwrap();
    quiet!("number of files: {FILES}");
    verbose!("appending number of files to shell script");
    file.write_all(unsafe { &FILES.to_be_bytes() }).unwrap();
}
fn get_files(path: impl AsRef<std::path::Path> + std::fmt::Debug, file: &mut std::fs::File) {
    verbose!("getting items from directory: {:?}", path);
    for item in std::fs::read_dir("src").unwrap() {
        if let Ok(item) = item {
            verbose!("item: {:?}", item);
            if let Ok(metadata) = item.metadata() {
                verbose!("valid metadata");
                if metadata.is_dir() {
                    verbose!("item is a directory: recursively calling this function with new path");
                    get_files(path.as_ref().join(item.file_name()), file)
                }
                else if metadata.is_file() {
                    verbose!("item is a file: getting data and appending");
                    file.write_all(
                        &ScriptFile::new(path.as_ref().join(item.file_name())).to_bytes()
                    ).unwrap();
                    verbose!("seeking to first unused byte after file");
                    file.seek(SeekFrom::End(-1)).unwrap();
                }
            }
            else {
                verbose!("invalid metadata")
            }
        }
    }
}
fn find_insert(shell_script: &mut String, find: &str, insert: &str) -> Option<()> {
    let index = shell_script.find(find)?;
    shell_script.insert_str(index+find.len(), insert);
    Some(())
}