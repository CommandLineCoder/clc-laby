clc-laby is a fork of the game laby, a game where a player learns programming by moving an ant using instructions.

Below are installation instructions to get clc-laby working on a newly imaged raspberry pi (bookworm) with java. 
At the time of writing, these are provisional and will be updated soon.


clc-laby installation instructions


sudo nano /etc/apt/sources.list
<Remove the # from the start of the deb-src lines, (Press Control X) to save and exit>

sudo apt update

sudo apt upgrade


sudo apt build-dep laby

sudo apt install devscripts

git clone https://github.com/CommandLineCoder/clc-laby.git

cd clc-laby

chmod 755 build

debuild -us -uc -b

cd ..

sudo dpkg -i ./clc-laby<version>.deb

sudo apt install default-jdk

laby
