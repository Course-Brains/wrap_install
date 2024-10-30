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
echo '' > Cargo.toml

# Cargo.lock data goes here
echo '' > Cargo.lock

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
