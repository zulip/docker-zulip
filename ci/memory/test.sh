#!/bin/bash

set -eux
set -o pipefail

# We should have started with enough memory allocated to run multi-process
worker_procs=$("${docker[@]:?}" exec zulip supervisorctl status zulip-workers:* | wc -l)

if [ "$worker_procs" = "1" ]; then
    echo "Zulip is unexpectedly running single-process workers; the container"
    echo "environment may not have enough RAM?"
    exit 1
fi

with() {
    echo "--file=./ci/memory/$1.yaml"
}

# Reduce the amount of RAM allocated to the container, see it go single-process
"${docker[@]}" "$(with low-memory)" up zulip --wait
worker_procs=$("${docker[@]:?}" exec zulip supervisorctl status zulip-workers:* | wc -l)
if [ "$worker_procs" != "1" ]; then
    exit 1
fi

# We can override this with QUEUE_WORKERS_MULTIPROCESS
"${docker[@]}" "$(with low-memory)" "$(with multiprocess)" up zulip --wait
worker_procs=$("${docker[@]:?}" exec zulip supervisorctl status zulip-workers:* | wc -l)
if [ "$worker_procs" = "1" ]; then
    exit 1
fi

# We can also override in the other direction
"${docker[@]}" "$(with multithreaded)" up zulip --wait
worker_procs=$("${docker[@]:?}" exec zulip supervisorctl status zulip-workers:* | wc -l)
if [ "$worker_procs" != "1" ]; then
    exit 1
fi
