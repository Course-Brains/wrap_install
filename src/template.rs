use std::{
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
        println!("Path length is {path_len}\nSeeking 4 forward");
        //file.seek(SeekFrom::Current(4)).unwrap();

        let mut buf = new_buf(path_len);
        println!("Reading {path_len} bytes for path");
        file.read_exact(&mut buf).unwrap();
        println!("Getting path from bytes");
        let path = String::from_utf8(buf).unwrap();
        println!("Path is {path}\nSeeking {path_len} forward");
        //file.seek(SeekFrom::Current(path_len as i64)).unwrap();

        let mut buf: [u8; 4] = [0; 4];
        println!("Reading data length");
        file.read_exact(&mut buf).unwrap();
        println!("Getting data length from bytes");
        let data_len = u32::from_be_bytes(buf);
        println!("Data length is {data_len}\nSeeking 4 forward");
        //file.seek(SeekFrom::Current(4)).unwrap();
        
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
}