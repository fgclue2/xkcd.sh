# xkcd.sh

> xkcd reader in bash shell script using icat (or chafa) and curl

![Image of xkcd.sh program, shows a comic and some alt text](xkcd.png)

xkcd.sh is a very simple xkcd reader that uses `icat` (or `chafa`) and `curl` to get an xkcd comic and show it in the terminal. It uses `icat` to show the images and `curl` to get the comic.

## Usage

- Just run the command with the comic number: `xkcd.sh 730`
- Or if you want the most recent comic, run: `xkcd.sh`
- Or even get a random comic: `xkcd.sh -r` or `xkcd.sh --random`
- `-t` or `--transcript` prints the transcript along with the image, but not very well. I don't recommend it.
