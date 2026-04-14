#!/usr/bin/env bash

cmd_exists() {
    if ! which "$1" >/dev/null 2>/dev/null; then
        echo "Do you have $1 installed? Please install it."
        return 1
    fi
}

cmd_exists kitten || exit 1
cmd_exists curl || exit 1
cmd_exists getopt || exit 1

usage() {
    echo "Usage: xkcd.sh [OPTIONS] [CID]"
    echo ""
    echo "Options:"
    echo "  -t, --transcript      Show transcript"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Arguments:"
    echo "  COMIC                 Comic # (e.g. xkcd.sh 927)"
}


options=$(getopt -o trh --name xkcd.sh --long transcript,random,help -- "$@")
eval set -- "$options"

while true; do
    case "$1" in
        -t|--transcript)
            SHOW_TRANSCRIPT=true; shift ;;
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
    echo "Loading latest comic..."
else
    echo "Loading comic ${CID}..."
fi

COMIC_TMP=$(mktemp --directory)
COMIC=$(get_comic "$CID")
MAGICK="magick"

which magick >/dev/null && magick --version >/dev/null || MAGICK="convert"

IMAGE=$(echo "${COMIC}" | jq -r '.img')
curl "$IMAGE" -o "$COMIC_TMP/image.png" 2>/dev/null
$MAGICK "$COMIC_TMP"/image.png -bordercolor white -border 30x30 "$COMIC_TMP"/padded.png

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

kitten icat --align left --background=white "$COMIC_TMP"/padded.png

echo "$ALT"
if [[ $SHOW_TRANSCRIPT == true ]]; then
    echo
    echo "${TRANSCRIPT}"
fi

/usr/bin/env rmdir --ignore-fail-on-non-empty "$COMIC_TMP"