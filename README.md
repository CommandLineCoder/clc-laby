clc-laby is a fork of the game laby, a game where a player learns programming by moving an ant using instructions.

The fork is targeted as people looking to learn java and running a Raspberry Pi. 

#Version History
12thJan2024 - Version 1.0 released with changes to java skeleton to make more features visible to the player


#Installation Instructions

Below are installation instructions to get clc-laby working on a newly imaged raspberry pi (bookworm) with java as the desired langauge to play with. 


sudo apt update

sudo apt upgrade

sudo apt install debhelper-compat ocaml-nox ocaml-findlib ocamlbuild dh-ocaml liblablgtk3-ocaml-dev liblablgtksourceview3-ocaml-dev devscripts default-jdk

git clone https://github.com/CommandLineCoder/clc-laby.git

cd clc-laby

chmod 755 build

make

ln -s ${PWD}/data ${HOME}/.config/laby 

./laby
