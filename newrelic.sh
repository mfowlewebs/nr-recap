#!/usr/bin/env bash

set -e
[ -z "$NEW_RELIC_API_KEY" ] && echo "Need NEW_RELIC_API_KEY" >2 && exit 1
[ -n "$1" ] && APP="$1" || APP=16882879
[ -z "$FILTER" ] && FILTER="name=WebTransactionTotalTime/"
[ -z "$FROM" ] && FROM=$(date --iso-8601=minutes -d "$(date +%Y/%m/)$(($(date +%-d) - 1))")
[ -z "$TO" ] && TO=$(date --iso-8601=minutes -d $(date +%D))
[ -z "$PERIOD" ] && PERIOD=$((60 * 60 * 24))

METRICS=$(\
	curl "https://api.newrelic.com/v2/applications/$APP/metrics.json" \
	-s \
	-H "X-Api-Key:$NEW_RELIC_API_KEY" \
	-G -d "$FILTER"
)

NAMES=$(echo "$METRICS" | jq -r '.metrics[].name')
VALUES="$(echo "$METRICS" | jq -r '.metrics[].values[]' | sort | uniq)"

filter="from=$FROM&to=$TO&period=$PERIOD"
for metric in $NAMES
do
	filter="${filter}&names[]=$metric"
done

RESULTS=$(
	curl "https://api.newrelic.com/v2/applications/$APP/metrics/data.json" \
	-s \
     -H "X-Api-Key:$NEW_RELIC_API_KEY" \
     -G -d "$filter"
)

echo $RESULTS


#mapfile -t metrics < <(
#)

#echo "All metrics for application:"
#for each in "${metrics[@]}"
#do
#	echo $each
#done


