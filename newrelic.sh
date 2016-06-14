#!/usr/bin/env bash

set -e

[ -z "$NEW_RELIC_API_KEY" ] && echo "Need NEW_RELIC_API_KEY" >2 && exit 1
[ -n "$1" ] && APP="$1" || APP=16882879
[ -z "$FILTER" ] && FILTER="name=WebTransactionTotalTime/"
[ -z "$DAYS_AGO" ] && DAYS_AGO=1
[ -z "$FROM" ] && FROM=$(date --iso-8601=minutes -d $(date +%D)" - $(($DAYS_AGO * 24)) hours")
[ -z "$TO" ] && TO=$(date --iso-8601=minutes -d $(date --iso-8601=minutes -d $FROM)" + 24 hours")
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


echo "name,from,to,$(echo $RESULTS | jq -r '.metric_data.metrics[0].timeslices[0].values| keys | join(",")')"
while read endpoint; do
	name=$(echo $endpoint | jq -r '.name')
	while read timeslice; do
		#echo "$name,$(echo $timeslice | jq -r '[.from, .to] + .values[] | join(",")')"
		echo "$name,$(echo $timeslice | jq -r '[.from, .to, .values[]] | map(tostring) | join(",") ')"
		#echo "$name,$(echo $timeslice | jq -r '.values | select()')"
	done < <(echo $endpoint | jq -c '.timeslices[]')
done < <(echo $RESULTS | jq -c '.metric_data.metrics[]')




#mapfile -t metrics < <(
#)

#echo "All metrics for application:"
#for each in "${metrics[@]}"
#do
#	echo $each
#done


