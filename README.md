clc-laby is a fork of the game laby, a game where a player learns programming by moving an ant using instructions.

Below are installation instructions to get clc-laby working on a newly imaged raspberry pi (bookworm) with java. 
At the time of writing, these are provisional and will be updated soon.


clc-laby installation instructions

sudo apt update

sudo apt upgrade

sudo apt install debhelper-compat ocaml-nox ocaml-findlib ocamlbuild dh-ocaml liblablgtk3-ocaml-dev liblablgtksourceview3-ocaml-dev devscripts
#note check in debian / control at top


Ignore line below for now
//sudo apt install libc6 libcairo2 libgdk-pixbuf-2.0-0 libglib2.0-0 libgtk-3-0 libgtksourceview-3.0-1 libpango-1.0-0 ocaml-nox default-jdk
//Double check line about doesnt contain typos on target system by copy and pasting. 
//(libraries can be confirmed by those listed after typing command apt show laby)

//sudo apt install devscripts


//sudo nano /etc/apt/sources.list
//<Remove the # from the start of the deb-src lines, (Press Control X) to save and exit>

//sudo apt build-dep laby


git clone https://github.com/CommandLineCoder/clc-laby.git

cd clc-laby

chmod 755 build

make

LN command in INSTALL. 

laby
