#!/bin/bash
# A template for the wrap install generated script

while true; do
    echo 'It is HIGHLY recommended to have this happen in an empty folder'
    echo 'If this is not in an empty folder, stop the script here and put it in one'
    echo "You can stop it by pressing control+c or if that doesn't work then you're a smart cookie, look it up"
    echo -n 'Do you have rustup? (y/n) '
    read input
    if [ $input == 'y' ]; then
        echo 'Installing, do not interact with this directory'
        break
    elif [ $input == 'n' ]; then
        echo 'On Unix systems(MacOS/Linux):'
        echo 'Run : curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh'
        echo 'On Windows:'
        echo 'Download: 'https://static.rust-lang.org/rustup/dist/i686-pc-windows-gnu/rustup-init.exe' then run the file'
        echo 'On success: rerun this file'
        echo "If you aren't on unix or windows, then figure it out yourself idk"
        exit
    fi
done

cargo new project

cd project

# Cargo.toml data goes here
echo '[package]
name = "wrap_install"
version = "0.2.0"
edition = "2021"

# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

[dependencies]
serde = { version = "1", features = ["derive"]}
toml = "0.8.12"' > Cargo.toml

# Title here too
echo 'const TITLE: &str = "../wrap_install.sh";' > int.rs
# Rust code here
echo 'use std::{
    io::{Seek, SeekFrom, Read},
    path::PathBuf,
    str::FromStr,
};
fn main() {
    println!("{:?}", TITLE);
    let mut file = std::fs::OpenOptions::new().read(true).open(TITLE).unwrap();

    println!("Seeking to 12 from end");
    file.seek(SeekFrom::End(-12)).unwrap();
    
    let mut buf: [u8; 8] = [0; 8];
    println!("Reading 8 bytes for start point");
    file.read_exact(&mut buf).unwrap();
    println!("Seeking to start point");
    let start = u64::from_be_bytes(buf);

    let mut buf: [u8; 4] = [0; 4];
    println!("Reading 4 bytes for number of files");
    file.read_exact(&mut buf).unwrap();
    let files: u32 = u32::from_be_bytes(buf);
    println!("Number of files: {files}");
    file.seek(SeekFrom::Start(start)).unwrap();

    for _ in 0..files {
        let mut buf = [0; 4];
        println!("Reading 4 bytes for path length");
        file.read_exact(&mut buf).unwrap();
        println!("Getting path length from bytes");
        let path_len = u32::from_be_bytes(buf);
        println!("Path length is {path_len}");

        let mut buf = new_buf(path_len);
        println!("Reading {path_len} bytes for path");
        file.read_exact(&mut buf).unwrap();
        println!("Getting path from bytes");
        let path = String::from_utf8(buf).unwrap();
        println!("Path is {path}");

        let mut buf: [u8; 4] = [0; 4];
        println!("Reading data length");
        file.read_exact(&mut buf).unwrap();
        println!("Getting data length from bytes");
        let data_len = u32::from_be_bytes(buf);
        println!("Data length is {data_len}");
        
        let mut buf = new_buf(data_len);
        println!("Reading {data_len} bytes for data");
        file.read_exact(&mut buf).unwrap();
        println!("Getting directory path from path({path})");
        let mut dir_path = PathBuf::from_str(&path).unwrap();
        dir_path.pop();
        println!("Directory path is {:?}\nCreating directories", dir_path);
        std::fs::create_dir_all(dir_path).unwrap();
        println!("Writing data to {path}");
        std::fs::write(path, buf).unwrap();
    }
}
fn new_buf(len: u32) -> Vec<u8> {
    let mut out = Vec::with_capacity(len as usize);
    for _ in 0..len {
        out.push(0u8)
    }
    out
}' >> int.rs

rustc int.rs --edition "2021"
./int

cargo build --release

cd ..

mv project/target/release/wrap_install$title .

rm -r project

exit
   src/template.sh  �#!/bin/bash
# A template for the wrap install generated script

while true; do
    echo 'It is HIGHLY recommended to have this happen in an empty folder'
    echo 'If this is not in an empty folder, stop the script here and put it in one'
    echo "You can stop it by pressing control+c or if that doesn't work then you're a smart cookie, look it up"
    echo -n 'Do you have rustup? (y/n) '
    read input
    if [ $input == 'y' ]; then
        echo 'Installing, do not interact with this directory'
        break
    elif [ $input == 'n' ]; then
        echo 'On Unix systems(MacOS/Linux):'
        echo 'Run : curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh'
        echo 'On Windows:'
        echo 'Download: 'https://static.rust-lang.org/rustup/dist/i686-pc-windows-gnu/rustup-init.exe' then run the file'
        echo 'On success: rerun this file'
        echo "If you aren't on unix or windows, then figure it out yourself idk"
        exit
    fi
done

cargo new project

cd project

# Cargo.toml data goes here
echo '' > Cargo.toml

# Title here too
echo 'const TITLE: &str = "../";' > int.rs
# Rust code here
echo '' >> int.rs

rustc int.rs --edition "2021"
./int

cargo build --release

cd ..

mv project/target/release/$title .

rm -r project

exit
   src/main.rs  5"use std::io::{Seek, SeekFrom, Write};

const TEMPLATE: &str = include_str!("template.sh");

static mut FILES: u32 = 0;
static mut MODE: Mode = Mode::Normal;


macro_rules! verbose {
    ($code: block) => {
        unsafe {
            if let Mode::Verbose = MODE {
                $code
            }
        }
    };
    ($code: stmt) => {
        unsafe {
            if let Mode::Verbose = MODE {
                $code
            }
        }
    }
}
macro_rules! quiet {
    ($code: block) => {
        unsafe {
            if let Mode::Quiet = MODE {}
            else {
                $code
            }
        }
    };
    ($code: stmt) => {
        unsafe {
            if let Mode::Quiet = MODE {}
            else {
                $code
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
        quiet!(println!("file({:?})", path));
        verbose!(println!("incrementing number of files by 1"));
        unsafe { FILES += 1 }
        verbose!(println!("numbre of files: {FILES}\ncreating data/header\nreading file for data"));
        let mut out = ScriptFile {
            header: None,
            data: std::fs::read(&path).unwrap()
        };
        verbose!(println!("creating header"));
        out.header = Some(Header::new(path, out.data.len() as u32));
        out
    }
    fn to_bytes(self) -> Vec<u8> {
        verbose!(println!("converting file data to raw bytes"));
        [self.header.unwrap().to_bytes(), self.data].concat()
    }
}
struct Header {
    path: String,
    data_len: u32,
}
impl Header {
    fn new(path: impl AsRef<std::path::Path> + std::fmt::Debug, data_len: u32) -> Self {
        verbose!(println!("creating header for {data_len} length data at {:?}", path));
        Header {
            path: path.as_ref().to_str().unwrap().to_owned(),
            data_len
        }
    }
    fn to_bytes(&self) -> Vec<u8> {
        verbose!(println!("converting header to raw bytes"));
        let mut output: Vec<u8> = Vec::new();
        verbose!(println!("adding path length to raw bytes"));
        output.extend_from_slice(&(self.path.len() as u32).to_be_bytes());
        verbose!(println!("adding path to raw bytes"));
        output.extend_from_slice(self.path.as_bytes());
        verbose!(println!("adding data length to raw bytes"));
        output.extend_from_slice(&self.data_len.to_be_bytes());
        verbose!(println!("done creating raw bytes from header"));
        output
    }
}
#[derive(serde::Deserialize)]
struct TomlSettings {
    optimize: Option<bool>,
    bin_name: Option<String>,
    shell_name: Option<String>,
    mode: Option<String>
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
            mode: None
        }
    }
}
struct Settings {
    optimize: bool,
    bin_name: Option<String>,
    shell_name: Option<String>,
    mode: Mode
}
impl Settings {
    fn get(path: impl AsRef<std::path::Path>) -> Settings {
        Settings::from(TomlSettings::get(path).unwrap())
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
        writeln!(f, "mode: {}", self.mode)
    }
}
#[derive(PartialEq, Clone, Copy)]
enum Mode {
    Normal,
    Quiet,
    Verbose
}
impl TryFrom<&str> for Mode {
    type Error = ();
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        match value.to_ascii_lowercase().as_str() {
            "verbose" => Ok(Mode::Verbose),
            "quiet" => Ok(Mode::Quiet),
            "normal" => Ok(Mode::Normal),
            _ => Err(())
        }
    }
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
    verbose!(println!("Settings from file: {settings}"));
    unsafe { MODE = settings.mode }
    // Changing settings based on arguments
    let mut args = std::env::args();
    while let Some(arg) = args.next() {
        verbose!(println!("argument: {arg}"));
        if arg == "--mode" {
            settings.mode = Mode::try_from(args.next().expect("Expected a value after '--mode'")).unwrap();
            unsafe { MODE = settings.mode }
        }
        else if arg == "--unoptimized" {
            settings.optimize = false
        }
        else if arg == "--bin-name" {
            let item = args.next().expect("Expected a value after '--bin-name'");
            verbose!(println!("argument value: {item}"));
            if item == "default" {
                verbose!(println!("overriding to default"));
                settings.bin_name = None
            }
            else {
                settings.bin_name = Some(item)
            }
        }
        else if arg == "--shell-name" {
            let item = args.next().expect("Expected a value after '--shell-name'");
            verbose!(println!("argument value: {item}"));
            if item == "default" {
                verbose!(println!("overriding to default"));
                settings.shell_name = None
            }
            else {
                settings.shell_name = Some(item)
            }
        }
    }
    quiet!(println!("Running with settings:\n{settings}"));
    let mut cargo = std::fs::read_to_string("Cargo.toml").unwrap();
    let manifest: CargoManifest = toml::from_str(&cargo).unwrap();
    let name = manifest.package.name;
    verbose!(println!("package name: {name}"));

    verbose!(println!("creating shell script string"));
    let mut shell_script = TEMPLATE.to_owned();

    // Insert things to the shell script starting from the back to prevent the chance
    // of false positives

    // Giving the name of the bin to the shell script
    verbose!(println!("changing bin name according to settings"));
    let bin_name = match settings.bin_name {
        Some(ref name) => {verbose!(println!("bin name: {name}")); name }
        None => {verbose!(println!("bin name: default({name})")); &name }
    };
    verbose!(println!("changing shell script string to have bin name: {bin_name}"));
    find_insert(&mut shell_script, "mv project/target/release/", bin_name);

    // Changes for unoptimized
    verbose!(println!("changing optimization according to settings"));
    if !settings.optimize {
        // Replacing the directory to get the binary from (release => debug)
        verbose!(println!("unoptimized\nchanging mv directory"));
        let mut index = shell_script.find("mv $dir_name/target/").unwrap()+"mv $dir_name/target/".len();
        for _ in 0.."release".len() {
            shell_script.remove(index);
        }
        shell_script.insert_str(index, "debug");
        // Changing cargo build --release to cargo build
        verbose!(println!("changing cargo build --release to not have release"));
        index = shell_script.find("cargo build").unwrap()+"cargo build".len();
        for _ in 0.." --release".len() {
            shell_script.remove(index);
        }
    }
    else {
        verbose!(println!("optimized: no change needed"))
    }
    
    // Putting in the int rust
    verbose!(println!("inserting extractor => shell script string"));
    find_insert(&mut shell_script, "# Rust code here\necho '", include_str!("template.rs")).unwrap();

    // Section for putting the name of the project in the int rust file
    verbose!(println!("inserting project name => shell script string"));
    find_insert(&mut shell_script,
        "\n# Title here too\necho 'const TITLE: &str = \"../",
        &(name.to_owned()+".sh")
    ).unwrap();

    // changing the toml file so that the bin name is correct
    verbose!(println!("setting bin name in cargo string"));
    if let Some(new_name) = &settings.bin_name {
        verbose!(println!("bin name changing to: {new_name}"));
        let mut table: toml::Table = cargo.parse().unwrap();
        if let toml::Value::Table(package) = table.get_mut("package").unwrap() {
            if let toml::Value::String(name) = package.get_mut("name").unwrap() {
                *name = new_name.clone()
            }
        }
        cargo = toml::to_string(&table).unwrap()
    }
    else {
        verbose!(println!("no change needed"))
    }

    // Putting the cargo data in
    verbose!(println!("inserting cargo data => shell script string"));
    find_insert(&mut shell_script,
        "\n# Cargo.toml data goes here\necho \'",
        &cargo
    ).unwrap();

    // Shell script file creation
    verbose!(println!("defining shell script path name from settings if needed"));
    let path_name: String;
    match settings.shell_name {
        Some(new_name) => {
            verbose!(println!("overriding shell script path name to: {new_name}"));
            path_name = new_name+".sh"
        }
        None => {
            verbose!(println!("shell script path name is default({name})"));
            path_name = name+".sh"
        }
    }
    verbose!(println!("creating shell script from shell script string"));
    std::fs::write(&path_name, shell_script).unwrap();
    // Shell script file insertion
    verbose!(println!("opening shell script({path_name}) to append raw file data"));
    let mut file = std::fs::OpenOptions::new().append(true).write(true).truncate(false).open(path_name).unwrap();
    verbose!(println!("getting current length of file for start position of data read"));
    let len = file.metadata().unwrap().len();
    verbose!(println!("start position is {len}\nseeking to end of file"));
    file.seek(SeekFrom::End(0)).unwrap();
    verbose!(println!("appending files in src to shell script"));
    get_files("src", &mut file);
    verbose!(println!("appending start position to shell script"));
    file.write_all(&len.to_be_bytes()).unwrap();
    quiet!(println!("number of files: {FILES}"));
    verbose!(println!("appending number of files to shell script"));
    file.write_all(unsafe { &FILES.to_be_bytes() }).unwrap();
}
fn get_files(path: impl AsRef<std::path::Path> + std::fmt::Debug, file: &mut std::fs::File) {
    verbose!(println!("getting items from directory: {:?}", path));
    for item in std::fs::read_dir("src").unwrap() {
        if let Ok(item) = item {
            verbose!(println!("item: {:?}", item));
            if let Ok(metadata) = item.metadata() {
                verbose!(println!("valid metadata"));
                if metadata.is_dir() {
                    verbose!(println!("item is a directory: recursively calling this function with new path"));
                    get_files(path.as_ref().join(item.file_name()), file)
                }
                else if metadata.is_file() {
                    verbose!(println!("item is a file: getting data and appending"));
                    file.write_all(
                        &ScriptFile::new(path.as_ref().join(item.file_name())).to_bytes()
                    ).unwrap();
                    verbose!(println!("seeking to first unused byte after file"));
                    file.seek(SeekFrom::End(-1)).unwrap();
                }
            }
            else {
                verbose!(println!("invalid metadata"))
            }
        }
    }
}
fn find_insert(shell_script: &mut String, find: &str, insert: &str) -> Option<()> {
    let index = shell_script.find(find)?;
    shell_script.insert_str(index+find.len(), insert);
    Some(())
}   src/template.rs  �use std::{
    io::{Seek, SeekFrom, Read},
    path::PathBuf,
    str::FromStr,
};
fn main() {
    println!("{:?}", TITLE);
    let mut file = std::fs::OpenOptions::new().read(true).open(TITLE).unwrap();

    println!("Seeking to 12 from end");
    file.seek(SeekFrom::End(-12)).unwrap();
    
    let mut buf: [u8; 8] = [0; 8];
    println!("Reading 8 bytes for start point");
    file.read_exact(&mut buf).unwrap();
    println!("Seeking to start point");
    let start = u64::from_be_bytes(buf);

    let mut buf: [u8; 4] = [0; 4];
    println!("Reading 4 bytes for number of files");
    file.read_exact(&mut buf).unwrap();
    let files: u32 = u32::from_be_bytes(buf);
    println!("Number of files: {files}");
    file.seek(SeekFrom::Start(start)).unwrap();

    for _ in 0..files {
        let mut buf = [0; 4];
        println!("Reading 4 bytes for path length");
        file.read_exact(&mut buf).unwrap();
        println!("Getting path length from bytes");
        let path_len = u32::from_be_bytes(buf);
        println!("Path length is {path_len}");

        let mut buf = new_buf(path_len);
        println!("Reading {path_len} bytes for path");
        file.read_exact(&mut buf).unwrap();
        println!("Getting path from bytes");
        let path = String::from_utf8(buf).unwrap();
        println!("Path is {path}");

        let mut buf: [u8; 4] = [0; 4];
        println!("Reading data length");
        file.read_exact(&mut buf).unwrap();
        println!("Getting data length from bytes");
        let data_len = u32::from_be_bytes(buf);
        println!("Data length is {data_len}");
        
        let mut buf = new_buf(data_len);
        println!("Reading {data_len} bytes for data");
        file.read_exact(&mut buf).unwrap();
        println!("Getting directory path from path({path})");
        let mut dir_path = PathBuf::from_str(&path).unwrap();
        dir_path.pop();
        println!("Directory path is {:?}\nCreating directories", dir_path);
        std::fs::create_dir_all(dir_path).unwrap();
        println!("Writing data to {path}");
        std::fs::write(path, buf).unwrap();
    }
}
fn new_buf(len: u32) -> Vec<u8> {
    let mut out = Vec::with_capacity(len as usize);
    for _ in 0..len {
        out.push(0u8)
    }
    out
}      �   