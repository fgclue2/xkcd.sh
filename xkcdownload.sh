#!/usr/bin/env bash

cmd_exists() {
    if ! which "$1" >/dev/null 2>/dev/null; then
        echo "Do you have $1 installed? Please install it."
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
    OUTPUT="$CID"
    curl "$IMAGE" -o "$OUTPUT.png" 2>/dev/null
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
echo "Saved to $OUTPUT"
echo "Alt: $ALT"