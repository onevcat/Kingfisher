# Prefetch concurrency investigation

Date: 2026-09-15. Environment: macOS 27.0, Xcode 27.0 (27A266a), Swift 6.4.
Baseline: `20facefe`, after enabling the prefetch tests during the SDK health check.

## Conclusion

The stress test has a real scaling problem. Adding subscribers to a shared download
performed quadratic priority calculations while other prefetch queues waited
synchronously. A tvOS Simulator thread sample reached the 512 dispatch-thread limit.
This is a credible mechanism for load-sensitive timeouts, not just an arbitrary short
expectation. The original failed run has no equivalent sample or completion counters,
so its exact cause cannot be proved retrospectively.

Four separate correctness defects also have deterministic regression tests. Their
triggers do not occur in the original stress test. Do not attribute that timeout to
these defects merely because they were found in the same investigation.

## Hypotheses and experiments

The original test starts 10,000 prefetchers, each with four distinct URLs, using
Nocilla responses and memory-only storage. That is 40,000 logical image requests,
with URLSession downloads shared between consumers. The 15-second limit is unchanged.

| Hypothesis | Experiment | Evidence |
| --- | --- | --- |
| Ordinary cold-path latency | Count unique completions, failures, cache hits, and downloaded sources; compare cold and preloaded memory cache | Baseline tvOS cold: 5.237 s; warm: 0.228 s. Both drained all 10,000 prefetchers, with zero failures or duplicate completions. |
| Lost callbacks or a memory race under the original workload | Longer diagnostic observation window, repeated cold runs, Thread Sanitizer | Three further baseline tvOS cold runs drained in 7.029, 3.258, and 2.525 s. Baseline macOS sanitizer cold/warm runs also drained completely, without a reported data race. This does not prove race freedom. |
| Contention and excessive registration work | Sample the actual cold tvOS workload; isolate shared-task registration cost | All 1,376 samples reported the dispatch hard limit of 512 threads. Prefetch threads waited in dispatch sync; the active requesting queue spent substantial time in `SessionDataTask.updateTaskPriority()` and `Sequence.max()`. |

The baseline sanitizer run also emitted a Thread Performance Checker QoS-inversion
warning in CFNetwork's private protocol scheduling setup. That warning is not a
Thread Sanitizer data-race report.

### Controlled priority experiment

Each new callback previously scanned all subscriber priorities. For n subscribers,
registration therefore did roughly 1 + 2 + ... + n comparisons. A new subscriber
can only raise the current maximum, so registration now checks its priority once.
The first subscriber still sets the task priority, including a low initial priority.
Priority removal, explicit updates, and resets retain their existing behavior.

A macOS Debug microbenchmark registered callbacks on a real `SessionDataTask` with
an inert URLSession task. No network or cache work was included:

| Subscribers | Before (seconds) | After (seconds) |
| ---: | ---: | ---: |
| 1,000 | 0.004535 | 0.001134 |
| 2,000 | 0.015916 | 0.002107 |
| 4,000 | 0.059019 | 0.004468 |
| 8,000 | 0.221628 | 0.009706 |
| 16,000 | 0.871145 | 0.019314 |

Doubling subscribers approximately quadrupled the old cost and doubled the new cost.
The isolated 16,000-subscriber registration improved by about 45 times. Four existing
priority behavior tests passed with the change.

Three tvOS diagnostic runs with only this optimization took 0.536, 3.549, and 1.841 s.
Their cache-hit counts were 39,076, 1, and 4,675 out of 40,000 sources. Those different
workloads do **not** support a precise end-to-end speedup claim. The controlled
microbenchmark establishes the removed hotspot; the simulator timings show the
remaining scheduling and cache sensitivity.

## Deterministic correctness regressions

| Trigger | Observed before the fix | Fix |
| --- | --- | --- |
| Two active providers share a cache key, then `stop()` | Only one provider was cancelled; completion reported one failure instead of two and the source completion handler ran twice | Identify each active consumer with a UUID; clear both completion handlers on the prefetch queue before delivery |
| `stop()` while an async request modifier is suspended | No task was registered for cancellation; the eventual request completed successfully | Register a cancellation holder before setup and attach the eventual download through the existing task-start reporting wrapper |
| Disk entry disappears between the prefetch probe and manager probe, with `alsoPrefetchToMemory` | Manager returned false without a callback; prefetch completion never ran | Honor the return value and fall back to loading; also handle cache retrieval failures |
| Two sources await retry decisions, then `stop()` | First retry decision triggered completion with only one source accounted for | Determine completion from final source counts, not from an empty download-task dictionary; drain pending sources once |

The tests control the modifier and retry decisions with explicit gates, use two
cancellation-observing providers for duplicate keys, and delete a real disk entry
between cache probes. All four tests failed before their respective fixes and pass
afterward. The retry test was added after the first three fixes and still reproduced
premature completion, confirming a separate accounting defect.

The final code also snapshots progress handlers on the serial prefetch queue, clears
both resource and source handlers there, and prevents a stopped prefetcher from
starting a fallback download. These changes keep callback state on its owning queue.

## Scope and decisions

- Keep the original stress test enabled, with 10,000 instances and a 15-second limit.
- Keep the shared synchronous requesting queue. The sample shows its thread-pressure
  cost, but removing it requires a separate ordering and downloader synchronization
  audit. This patch removes the measured quadratic work without changing that model.
- Cancellation remains cooperative: providers, modifiers, and retry strategies must
  eventually finish or deliver their required callbacks. A pending decision is no
  longer mistaken for a completed source.
- No claim of universal prefetch race freedom, a guaranteed latency bound, or physical
  device performance follows from these synthetic tests. Mass cancellation and
  repeated explicit priority updates still scan subscriber priorities.
- No deployment-target changes are needed for these fixes. No demo behavior was changed
  or revalidated in this follow-up; the SDK health-check report contains that evidence.

## Evidence and reproduction

Artifacts: `/Users/onevcat/Downloads/kingfisher-prefetch-investigation-20260915`.

- `stress-sample.txt`: actual baseline tvOS stacks and dispatch-thread limit.
- `priority-before.log`, `priority-after.log`: isolated registration experiment.
- `tvos-observed.log`, `tvos-repeat.log`, `tvos-priority-only.log`: diagnostic counters.
- `repros-red.log`, `modifier-red.log`, `retry-red.log`: failing regressions.
- `instrumented-tests.swift`: diagnostic workload and benchmark retained outside the
  product test suite. The diagnostic observation timeout was 60 seconds; it did not
  replace the original 15-second test.
- `run-validation.sh`: exact final validation commands, destinations, and result paths.
- `*.xcresult` and raw logs: test receipts. Intermediate `repros-green.log` records
  a helper-access compile error that was corrected before the clean green run.

## Final validation

| Run | Result | Original stress duration |
| --- | --- | --- |
| macOS full suite | 396 passed, zero compiler warnings | 2.237 s |
| tvOS 27 full suite | 433 passed, zero compiler warnings | 1.937 s |
| iOS 27 full suite | 435 passed, zero compiler warnings | 1.736 s |
| tvOS original stress, five consecutive iterations | 5 passed, unchanged 15-second limit | 2.193, 2.665, 2.585, 2.153, 1.987 s |
| macOS prefetch suite with Thread Sanitizer | 15 passed, no reported data race | 3.616 s |

The final sanitizer run retained one Thread Performance Checker warning in CFNetwork
private protocol run-loop initialization, with the same stack family as the baseline.
It is recorded in `tsan-final.log`; it was not suppressed. Normal builds had no
compiler warnings. `git diff --check` also passed.

These runs were serialized to avoid adding simultaneous build/test load. The final
stress timings show successful completion under these conditions, not a latency
guarantee when the machine is under arbitrary load.
