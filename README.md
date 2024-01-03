clc-laby is a fork of the game laby, a game where a player learns programming by moving an ant using instructions.

Below are installation instructions to get clc-laby working on a newly imaged raspberry pi (bookworm) with java. 
At the time of writing, these are provisional and will be updated soon.


clc-laby installation instructions

sudo apt upgrade

sudo nano /etc/apt/sources.list
<Remove the # from the start of the deb-src lines, save and exit>

sudo apt update

sudo apt build-dep laby

git clone https://github.com/CommandLineCoder/clc-laby.git

cd clc-laby

chmod 755 build

make

sudo apt install laby

sudo apt install default-jdk

./laby
