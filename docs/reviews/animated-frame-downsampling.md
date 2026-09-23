# Animated frame downsampling validation

## Scope

This change continues [PR #2574](https://github.com/onevcat/Kingfisher/pull/2574).
It preserves all four commits by @omarH2007 through `2857ccc2`.
The follow-up commit `ef6b6ba6` fixes two loading races:

- Keep the initial buffer fill pending when consecutive layout changes supersede the first frame load.
- Stop an active preload batch after its animator is cancelled.

The integration commit is `4418e596`. The comparison baseline is master
`2fd07d849eee37bc756eb6b54f270a6882cef046`. The final follow-up adds a pixel
regression test and this report; it does not change the measured runtime code.

## Correctness

The regression tests cover zero-sized initial layout, consecutive layout changes,
frame buffer refill, cancellation, view growth, content modes, backing scale,
image replacement, stopped animation, and the `needsPrescaling = false` opt-out.
Both loading-race tests failed before the follow-up fix and passed after it.

The new pixel test compares every frame of the existing eight-frame GIF with a
full-size ImageIO frame rendered into the same thumbnail-sized RGBA context.
All bytes match on macOS, iOS, tvOS, and visionOS. A mutation that returns frame
zero for each requested index fails seven comparisons, which confirms that the
test detects incorrect frame selection.

An independent macOS probe also compared five frames of the large demo GIF and
five frames of the test GIF. All ten comparisons were byte-identical after
rendering at the same dimensions. This checks these fixtures, not every image
format or color profile.

## Local checks

Xcode 27 was used for these checks. All listed checks passed.
The full suites ran before the final test-only change; the new pixel test then
passed separately on all four platforms.

| Platform | Check | Passed tests |
| --- | --- | ---: |
| macOS 27 | Full suite | 433 |
| iOS 27 Simulator | Full suite | 475 |
| tvOS 27 Simulator | Animator, layout, and image extension tests | 45 |
| visionOS 27 Simulator | Animator, layout, and image extension tests | 45 |
| macOS / iOS / tvOS / visionOS | New pixel test, each platform | 1 |
| watchOS Simulator | Build | N/A |

The macOS failure seen on the old PR base was an existing Data pointer-identity
test assumption. The current master already contains its fix; no duplicate fix
was added here.

## Native app validation

A temporary Release app used public Kingfisher APIs on macOS, iOS Simulator,
and an iPhone 15 Pro Max running iOS 26.6.2. It checked playback, stop, resize
from 90 to 180 points while stopped, a scaling-mode change, resume, and five
consecutive image replacements. Playback continued after replacement.
Screenshots confirmed the expected display on all three targets.

On the physical iPhone, the paused frame index stayed at 51 while its decoded
size grew from 270 x 152 to 540 x 304 pixels. Aspect fill requested 960 x 540
pixels without restarting playback. Resume advanced the frame index to 86;
replacement then started the new animation. On macOS, proportional scaling
produced 180 x 101 and then 360 x 202 pixels; independent-axis scaling requested
640 x 360 pixels. The paused frame index stayed at 52.

## Memory method

The fixture was the existing [GIF Heavy demo asset](https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/GIF/GifHeavy.gif):
1,732,950 bytes, 2560 x 1440 pixels, 619 frames.
Each fresh Release process displayed four 90 x 90 point animated views with
aspect-fit scaling and `framePreloadCount = 2`. The source was a local file;
network requests and Kingfisher disk caching were outside this measurement.
Both builds used the same harness and fixture on each platform.

The harness sampled `task_vm_info.phys_footprint` every 0.1 seconds for 20
seconds. Each run's steady value is the median of samples from 8 to 20 seconds.
The sampled peak is the largest footprint sample in that run. Each build ran
three times. Summary values are medians of the three run values, in MiB.
A sampled peak can miss a shorter allocation spike.

Fixture SHA-256: `babef79a8fdbce6a2759dcabd061182d4d46494e77b38cf40db7d52f64d2bf98`.

## Memory results

| Device | Baseline steady | Patched steady | Reduction | Baseline sampled peak | Patched sampled peak | Reduction |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| M2 Pro / macOS 27 | 282.19 | 217.53 | 22.9% | 338.95 | 281.34 | 17.0% |
| iPhone 15 Pro Max / iOS 26.6.2 | 430.60 | 251.06 | 41.7% | 509.52 | 312.45 | 38.7% |

| Platform | Build | Run | Steady MiB | Sampled peak MiB |
| --- | --- | ---: | ---: | ---: |
| mac | baseline | 1 | 282.19 | 338.95 |
| mac | baseline | 2 | 282.09 | 338.72 |
| mac | baseline | 3 | 283.60 | 340.02 |
| mac | patched | 1 | 216.77 | 277.70 |
| mac | patched | 2 | 217.53 | 286.22 |
| mac | patched | 3 | 217.56 | 281.34 |
| physical | baseline | 1 | 430.60 | 504.31 |
| physical | baseline | 2 | 430.49 | 521.19 |
| physical | baseline | 3 | 444.27 | 509.52 |
| physical | patched | 1 | 249.41 | 308.11 |
| physical | patched | 2 | 251.31 | 321.06 |
| physical | patched | 3 | 251.06 | 312.45 |

The third physical baseline attempt was interrupted when another app became
foreground. It produced no report and is excluded. Its replacement completed
normally. All six retained physical runs contain 199 or 200 samples over 20
seconds, with no sampling gap above 0.3 seconds. Their final frame indices were
close (237 to 241), and all four views remained animated.

The decoded frame size was 2560 x 1440 on the baseline, 180 x 101 on patched
macOS, and 270 x 152 on patched iPhone. The macOS baseline reached about frame
192 while the patched build reached about frame 254 in the same interval.
The benchmark measures continuous playback, not a fixed frame sequence, and
was not designed as a frame-pacing or CPU benchmark.

## Limits

These results establish a memory improvement for this large-GIF, small-view
workload. They do not establish an app-wide percentage, an energy improvement,
or protection against all memory-pressure termination. ImageIO still needs
source decoding and composition storage, so process footprint does not shrink
in proportion to the thumbnail pixel count. The sampled peak remains material.

Layout sizing follows view bounds and content mode. Transform-only zoom does
not enlarge those bounds; clients that need native-resolution frames can use
`needsPrescaling = false`. No new public configuration is required.
