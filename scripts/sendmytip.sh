#!/bin/bash
# Reports block height to pooltool.io every 5 seconds  
# Based on https://github.com/papacarp/pooltool.io/blob/master/sendmytip/shell/systemd/sendmytip.sh
# and https://cardano.stakepool.quebec/scripts/qcpolsendmytip.sh
# Should be started as a systemd service

POOL_ID="pool-id"
API_KEY="api-key-from-pooltool"
NODE_ID="PRX-Core" # not used at the moment

PLATFORM="Proxima Pool"

nodeVNumber=$(docker exec corenode cardano-node --version | awk '/cardano-node/ {print $2}')
nodeGitRev=$(docker exec corenode cardano-node --version | awk '/rev/ {print $3}' | cut -c1-5)
nodeVersion="$nodeVNumber":"$nodeGitRev"
lastSentBlockHeight="-1"

while true
do
    dateUtc=$(date '+%Y-%m-%dT%H:%M:%S.%2NZ')
    CCLI_TIP=$(docker exec corenode cardano-cli query tip --mainnet)
    nodeTip=$(echo $CCLI_TIP | jq -r '.slot, .hash, .block')
    lastSlot=$(echo $nodeTip | cut -d' ' -f1)
    lastBlockHash=$(echo $nodeTip | cut -d' ' -f2)
    lastBlockHeight=$(echo $nodeTip | cut -d' ' -f3)

    if [[ "$lastSentBlockHeight" != "$lastBlockHeight" && "$lastBlockHeight" != "" ]]; then
        JSON="$(jq -n --compact-output --arg NODE_ID "$NODE_ID" --arg MY_API_KEY "$API_KEY" --arg MY_POOL_ID "$POOL_ID" --arg VERSION "$nodeVersion" --arg AT "$dateUtc" --arg BLOCKNO "$lastBlockHeight" --arg SLOTNO "$lastSlot" --arg PLATFORM "$PLATFORM" --arg BLOCKHASH "$lastBlockHash" '{apiKey: $MY_API_KEY, poolId: $MY_POOL_ID, data: {nodeId: $NODE_ID, version: $VERSION, at: $AT, blockNo: $BLOCKNO, slotNo: $SLOTNO, blockHash: $BLOCKHASH, platform: $PLATFORM}}')"
        response="$(curl -s -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "$JSON" "https://api.pooltool.io/v0/sendstats")"
        #echo $JSON
        lastSentBlockHeight=$lastBlockHeight
    fi

    sleep 5
done
