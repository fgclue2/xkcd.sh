#!/usr/bin/env bash

cmd_exists() {
    if ! which "$1" >/dev/null 2>/dev/null; then
        echo "Do you have $1 installed? Please install it."
        return 1
    fi
}

quietcmdexists() {
    if ! which "$1" >/dev/null 2>/dev/null; then
        return 1
    fi
}

cmd_exists curl || exit 1
cmd_exists getopt || exit 1

usage() {
    echo "Usage: xkcdownload.sh [OPTIONS] [CID]"
    echo ""
    echo "Options:"
    echo "  -o, --otput           Output file"
    echo "  -r, --random          Choose a random comic"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Arguments:"
    echo "  COMIC                 Comic # (e.g. xkcdownload.sh 927)"
}


options=$(getopt -o o:rh --name xkcdownload.sh --long output:,random,help -- "$@")
eval set -- "$options"

while true; do
    case "$1" in
        -o|--output)
            OUTPUT="$2.png"; shift ;;
        -r|--random)
            RANDOM_COMIC=true; shift ;;
        -h|--help)
            usage; exit 0 ;;
        --) shift; break ;;
        *) break ;;
    esac
done

get_comic () {
    # shellcheck disable=SC2005 # echo is not useless
    echo "$(curl https://xkcd.com/"$1"/info.0.json 2>/dev/null | jq '.')"
}

random_comic() {
    LC="$(curl https://xkcd.com/"$1"/info.0.json 2>/dev/null | jq '.num')"
    echo "$(shuf -i 1-${LC} -n 1)"
}

CID="${1:-}"

if [[ $RANDOM_COMIC == true ]] then
    CID=$(random_comic)
fi

if [[ $CID == "" ]] then
    echo "Downloading latest comic..."
else
    echo "Downloading comic ${CID}..."
fi

COMIC=$(get_comic "$CID")
IMAGE=$(echo "${COMIC}" | jq -r '.img')

if [[ -v OUTPUT ]] then
    curl "$IMAGE" -o "$OUTPUT" 2>/dev/null
else
    OUTPUT="$CID.png"
    curl "$IMAGE" -o "$OUTPUT" 2>/dev/null
fi

echo -e "\033[1A\033[2K"


TITLE=$(echo "${COMIC}" | jq -r '.title')
NUMBER=$(echo "${COMIC}" | jq -r '.num')

YEAR=$(echo "${COMIC}" | jq -r '.year')
MONTH=$(printf %02d "$(echo "${COMIC}" | jq -r '.month')")
DAY=$(printf %02d "$(echo "${COMIC}" | jq -r '.day')")

DATE="$YEAR-$MONTH-$DAY"
ALT=$(echo "${COMIC}" | jq -r '.alt')

TRANSCRIPT=$(echo "${COMIC}" | jq -r '.transcript')

echo -e "\033[1A#${NUMBER}: $TITLE"
echo "published $DATE"
echo

# COMIC RENDERING STARTS HERE
#FROM https://sw.kovidgoyal.net/kitty/graphics-protocol/#a-minimal-example
send_chunked() {
    first="y"
    while IFS= read -r chunk; do
        metadata=""; [ "$first" = "y" ] && { metadata="a=T,f=100,"; first="n"; }
        printf "\033_G%sm=1;%s\033\\" "${metadata}" "${chunk}"
    done
    [ "$first" = "n" ] && { printf "\033_Gm=0;\033\\"; return 0; }
    return 1
}
# also from https://sw.kovidgoyal.net/kitty/graphics-protocol/#a-minimal-example
transmit_png() {
    # Different systems have different or missing base64 executables.
    # The sed command below adds a trailing newline which openssl
    # base64 does not produce and is needed for reading via read -r
    { command base64 -w 4096 "$1" 2>/dev/null | send_chunked; } || \
    { command base64 -b 4096 "$1" 2>/dev/null | send_chunked; } || \
    { command openssl base64 -e -A -in "$1" | command sed '$a\' | command fold -b -w 4096 | send_chunked; }
}

quietcmdexists kitten
HAS_KITTEN="$?"
quietcmdexists chafa
HAS_CHAFA="$?"

# checking for kitty terminal protocol
kitten icat 2>/dev/null || HAS_KITTEN=1

if [[ $HAS_KITTEN == 0 ]] then
    kitten icat --align left --background=white "$COMIC_TMP"/padded.png
elif [[ $HAS_CHAFA == 0 ]] then
    chafa "$COMIC_TMP"/padded.png
else
    transmit_png "$COMIC_TMP"/padded.png
    echo
fi

echo
echo "Saved to $OUTPUT"
echo "Alt: $ALT"
# ENDS HERE