# Issue #2495 Analysis: Disk Cache Deserialization Cannot Be Cancelled

## 1. Issue Overview

**Issue**: [#2495 - Images loading from cache are not canceled](https://github.com/onevcat/Kingfisher/issues/2495)
**Reporter**: FaizanDurrani
**Status**: Open

### Symptom

When scrolling quickly through a large collection of images, memory usage explodes (>1 GB). The reporter uses `KingfisherWebP` and observes that `ImageCache.retrieveImageInDiskCache` is called for every displayed item, even after `imageView.kf.cancelDownloadTask()` is invoked.

### Instruments Evidence

The attached Instruments Allocations screenshot shows:

- **Memory peak ~630 MB** during fast scrolling
- Heaviest allocation stack:
  - `ImageCache.retrieveImageInDiskCache(forKey:options:callbackQueue:completionHandler:)` — **218.55 MB**
  - `KingfisherWrapper.image(webpData:options:)` — **181.09 MB**
  - WebP decode + `CGImageCreate` calls downstream

The majority of memory is consumed by WebP deserialization, not by disk I/O itself.

---

## 2. Root Cause Analysis

The problem has two layers:

### Layer 1: Cache Retrieval Is Not Cancellable

`cancelDownloadTask()` calls `DownloadTask.cancel()`, which only cancels the **network** download (`SessionDataTask.cancel(token:)` in `ImageDownloader.swift:121-124`).

For images that hit the disk cache, `KingfisherManager.retrieveImage` returns `nil` at line 444 — there is no `DownloadTask` to cancel. Once `retrieveImageInDiskCache` dispatches its block to `ioQueue`, the entire chain (disk read → deserialization → memory promotion → callback) runs to completion with no interruption point.

### Layer 2: Eager Disk-to-Memory Promotion

Kingfisher's cache architecture is designed as "eager read into memory":

1. `ImageCache.retrieveImage` (line 608-655) checks memory first, then falls back to disk.
2. On disk hit, the image is **fully deserialized** via `CacheSerializer.image(with:data:options:)` on `ioQueue` (line 738).
3. The deserialized image is **unconditionally stored into memory cache** via `store(image, toDisk: false)` (line 641-645).
4. There is no lazy decode path, no thumbnail downsampling, and no option to skip memory promotion.

During fast scrolling, each reused cell triggers a new `setImage` call. The previous cell's disk cache retrieval is already enqueued on the serial `ioQueue`. With N cells scrolled through rapidly, N deserialization blocks queue up. WebP decoding is particularly expensive — each decode allocates significant memory. The combined allocations exceed `NSCache`'s eviction speed, causing the memory spike.

### Why Existing Mechanisms Don't Help

| Mechanism | Why It Doesn't Help |
|-----------|-------------------|
| `cancelDownloadTask()` | Returns nil for cache hits — nothing to cancel |
| `taskIdentifier` check in view completion (line 331) | Only runs **after** deserialization completes — the damage is done |
| `fromMemoryCacheOrRefresh` option | Skips disk cache entirely — loses all disk caching, not a valid workaround |
| `NSCache` eviction (totalCostLimit = 25% RAM) | LRU eviction is reactive, can't keep up with burst allocations |

---

## 3. Proposed Solution

### Approach: Source Task Identifier Check Before Deserialization

Leverage the existing `Source.Identifier` / `taskIdentifier` mechanism — which already works at the view layer — and extend it into the cache retrieval path. The check is inserted **before the expensive deserialization step**, skipping decode for tasks that are no longer relevant.

### Key Properties

- **No public API changes** — all modifications are internal
- **Backward compatible** — direct `KingfisherManager` callers are unaffected (checker is nil)
- **Completion handler contract preserved** — every `setImage` call produces exactly one completion callback
- **Worst case identical to current behavior** — if the check doesn't fire in time, the decode proceeds as it does today

### Changes Required

#### 3.1 `KingfisherParsedOptionsInfo` — New Internal Property

Add a closure property that flows through the options chain:

```swift
var sourceTaskIdentifierChecker: (@Sendable () -> Bool)?
```

Returns `true` if the task is still current, `false` if it has been superseded. This property is internal — not exposed in the public `KingfisherOptionsInfoItem` enum.

#### 3.2 `KingfisherManager.retrieveImage` — Store Checker in Options

Currently `referenceTaskIdentifierChecker` (line 306) is only applied to `onDataReceived` side effects (line 329-332). Add one line to also store it in options:

```swift
if let checker = referenceTaskIdentifierChecker {
    options.onDataReceived?.forEach {
        $0.onShouldApply = checker
    }
    options.sourceTaskIdentifierChecker = checker  // NEW
}
```

This ensures the checker propagates to `ImageCache` via the options struct.

#### 3.3 `ImageCache.retrieveImageInDiskCache` — Two Check Points

Insert checks **before disk read** and **before deserialization**:

```swift
func retrieveImageInDiskCache(
    forKey key: String,
    options: KingfisherParsedOptionsInfo,
    callbackQueue: CallbackQueue = .untouch,
    completionHandler: @escaping @Sendable (Result<KFCrossPlatformImage?, KingfisherError>) -> Void)
{
    let computedKey = key.computedKey(with: options.processor.identifier)
    let loadingQueue: CallbackQueue = options.loadDiskFileSynchronously ? .untouch : .dispatch(ioQueue)
    loadingQueue.execute {
        // CHECK 1: Skip entirely for queued blocks where the task is already stale.
        // This is the most common hit during fast scrolling — the block was waiting
        // in the serial queue while the main thread issued newer setImage calls.
        if let checker = options.sourceTaskIdentifierChecker, !checker() {
            callbackQueue.execute { completionHandler(.success(nil)) }
            return
        }

        do {
            var image: KFCrossPlatformImage? = nil
            if let data = try self.diskStorage.value(
                forKey: computedKey,
                forcedExtension: options.forcedExtension,
                extendingExpiration: options.diskCacheAccessExtendingExpiration
            ) {
                // CHECK 2: After disk read (cheap) but before deserialization (expensive).
                // Catches cases where the task became stale during a slow disk read
                // (e.g., large files on a busy I/O subsystem).
                if let checker = options.sourceTaskIdentifierChecker, !checker() {
                    callbackQueue.execute { completionHandler(.success(nil)) }
                    return
                }
                image = options.cacheSerializer.image(with: data, options: options)
            }
            if options.backgroundDecode {
                image = image?.kf.decoded(scale: options.scaleFactor)
            }
            callbackQueue.execute { [image] in completionHandler(.success(image)) }
        } catch let error as KingfisherError {
            callbackQueue.execute { completionHandler(.failure(error)) }
        } catch {
            assertionFailure("The internal thrown error should be a `KingfisherError`.")
        }
    }
}
```

Returning `.success(nil)` uses the same semantics as "image not found on disk", which is safely handled by all upstream callers.

#### 3.4 `KingfisherManager.retrieveImageFromCache` — Prevent Spurious Download (Path 2 Only)

`retrieveImageFromCache` has two code paths:

- **Path 1** (line 639-697): Processed image lookup. On `.none` result, calls `completionHandler(.failure(.imageNotExisting))`. Since `retrieveImageFromCache` already returned `true` synchronously, no download is triggered. **No change needed.**

- **Path 2** (line 716-793): Original image fallback with custom processor. On `.none` result, calls `self.loadAndCacheImage(...)` (line 732) — this **does** trigger a download. Add a check here:

```swift
guard let image = cacheResult.image else {
    // NEW: Task is stale — report error instead of downloading.
    if let checker = options.sourceTaskIdentifierChecker, !checker() {
        let error = KingfisherError.cacheError(reason: .imageNotExisting(key: key))
        options.callbackQueue.execute { completionHandler?(.failure(error)) }
        return
    }

    if options.onlyFromCache {
        let error = KingfisherError.cacheError(reason: .imageNotExisting(key: key))
        options.callbackQueue.execute { completionHandler?(.failure(error)) }
    } else {
        let task = self.loadAndCacheImage(
            source: source,
            context: context,
            completionHandler: completionHandler
        )
        downloadTaskUpdated?(task?.value)
    }
    return
}
```

### Summary of File Changes

| File | Change | Lines Affected |
|------|--------|---------------|
| `Sources/General/KingfisherOptionsInfoItems.swift` | Add `sourceTaskIdentifierChecker` property | ~1 line |
| `Sources/General/KingfisherManager.swift` | Store checker in options | ~1 line |
| `Sources/Cache/ImageCache.swift` | Two cancellation checks in `retrieveImageInDiskCache` | ~10 lines |
| `Sources/General/KingfisherManager.swift` | Prevent spurious download in path 2 | ~5 lines |

**Total: ~17 lines of effective code.**

---

## 4. Timing and Behavior Simulation

### Scenario A: Fast Scrolling (Primary Problem Case)

A cell is reused 5 times within one layout pass. All `setImage` calls complete on the main thread before the serial `ioQueue` processes any block.

```
Main thread (single runloop pass):
  cellForItem → cell X: setImage(url_1), X.taskId = 101, dispatch block_1 to ioQueue
  cellForItem → cell X: setImage(url_5), X.taskId = 102, dispatch block_2 to ioQueue
  cellForItem → cell X: setImage(url_9), X.taskId = 103, dispatch block_3 to ioQueue
  cellForItem → cell X: setImage(url_13), X.taskId = 104, dispatch block_4 to ioQueue
  cellForItem → cell X: setImage(url_17), X.taskId = 105, dispatch block_5 to ioQueue
                                                                         ↕ main thread yields

ioQueue (serial, starts processing):
  block_1: CHECK 1 → X.taskId==101? → 105≠101 → SKIP (no disk read, no decode)
  block_2: CHECK 1 → X.taskId==102? → 105≠102 → SKIP
  block_3: CHECK 1 → X.taskId==103? → 105≠103 → SKIP
  block_4: CHECK 1 → X.taskId==104? → 105≠104 → SKIP
  block_5: CHECK 1 → X.taskId==105? → 105==105 → read disk → CHECK 2 → still valid → DECODE ✓
```

**Result**: 4 out of 5 decodes skipped. Only the actually-needed image is decoded.
**Current behavior**: All 5 images decoded, all promoted to memory, 4 results discarded at view layer.
**Check hit rate**: (N-1)/N → approaches 100% with faster scrolling.

### Scenario B: Moderate Scrolling

User scrolls at a pace where each cell stays visible for ~200ms. Decode takes ~100ms per image.

```
Main thread:
  t=0ms    setImage(url_1), X.taskId = 101, dispatch block_1

ioQueue:
  t=5ms    block_1: CHECK 1 → 101==101 ✓ → read disk (10ms)
  t=15ms   CHECK 2 → 101==101 ✓ → decode (100ms)
  t=115ms  decode complete → store to memory → callback

Main thread:
  t=200ms  cell reuse, setImage(url_5), X.taskId = 102, dispatch block_2
```

**Result**: Decode completes before cell reuse. Check does not fire.
**Current behavior**: Identical — image was needed and displayed.
**Impact**: None — and none needed, since one-at-a-time decode doesn't cause memory pressure.

### Scenario C: Moderate Scrolling with Large File

Same pace as B, but a very large WebP file takes 300ms to read from disk.

```
Main thread:
  t=0ms    setImage(url_1), X.taskId = 101, dispatch block_1

ioQueue:
  t=5ms    block_1: CHECK 1 → 101==101 ✓ → start disk read (300ms)

Main thread:
  t=200ms  cell reuse, setImage(url_5), X.taskId = 102

ioQueue:
  t=305ms  disk read complete → CHECK 2 → 101==102? → 101≠102 → SKIP decode ✓
```

**Result**: CHECK 2 catches the stale task after a slow disk read. Decode skipped.
**Current behavior**: Full decode runs (expensive), result discarded at view layer.
**This is where the two-check design pays off** — CHECK 1 was valid at dispatch time, but CHECK 2 catches the change.

### Scenario D: Multiple Visible Cells (No Reuse)

10 cells appear simultaneously on initial load. Each cell has a different image, no cell reuse occurs.

```
Main thread:
  cell A: setImage(url_1), A.taskId = 101
  cell B: setImage(url_2), B.taskId = 102
  ...
  cell J: setImage(url_10), J.taskId = 110

ioQueue:
  block for cell A: CHECK → A.taskId==101? → 101==101 ✓ → decode
  block for cell B: CHECK → B.taskId==102? → 102==102 ✓ → decode
  ...
  block for cell J: CHECK → J.taskId==110? → 110==110 ✓ → decode
```

**Result**: All 10 images decoded. This is correct — all 10 are needed.
**Current behavior**: Identical.
**Impact**: None. The check is per-cell (each cell has its own `taskIdentifier`), so concurrent requests for different cells don't interfere with each other.

### Scenario E: Fast Scrolling with Custom Processor (Path 2)

User has a custom `ImageProcessor`. Original image is cached on disk, processed version is not. Cell reuses rapidly.

```
Main thread:
  setImage(url_1, processor: blur), X.taskId = 101
  setImage(url_5, processor: blur), X.taskId = 102

retrieveImageFromCache:
  Path 1: processed image not cached → validCache = false
  Path 2: original image cached → canUseOriginalImageCache = true

  originalCache.retrieveImage → ioQueue:
    block_1: CHECK → 101==102? → SKIP decode → .success(nil)

  Path 2 callback:
    cacheResult.image == nil
    → CHECK: 101==102? → stale
    → completionHandler(.failure(.imageNotExisting))   ← no download triggered ✓

  View layer:
    issuedIdentifier(101) ≠ taskIdentifier(102) → .notCurrentSourceTask
    completionHandler(.failure(.notCurrentSourceTask)) ← user gets callback ✓
```

**Without the path 2 fix**: `loadAndCacheImage` would be called, triggering a network download that is ultimately discarded.

---

## 5. Completion Handler Contract Verification

**Contract**: Every `setImage` call produces exactly one completion callback.

### For the "skipped" task (stale identifier):

```
retrieveImageInDiskCache → .success(nil)          // skipped decode
    ↓
ImageCache.retrieveImage → .success(.none)         // treated as "not found"
    ↓
retrieveImageFromCache:
  Path 1 → completionHandler(.failure(.imageNotExisting))    ✅ called
  Path 2 → checker prevents download,
           completionHandler(.failure(.imageNotExisting))    ✅ called
    ↓
handler (line 386) → failCurrentSource → completionHandler(.failure(...))
    ↓
View extension (line 331):
  issuedIdentifier ≠ taskIdentifier →
  completionHandler(.failure(.notCurrentSourceTask))         ✅ user receives callback
```

### For the "current" task (valid identifier):

Behavior is identical to today — full decode, memory promotion, success callback. No changes in this path.

---

## 6. Risk Assessment

### 6.1 Thread Safety of `taskIdentifier` Access

**Status**: Pre-existing issue, not introduced by this change.

The checker closure `{ issuedIdentifier == self.taskIdentifier }` reads `taskIdentifier` (associated object on UIImageView) from `ioQueue`, while writes happen on `@MainActor`. The associated object uses `OBJC_ASSOCIATION_RETAIN_NONATOMIC`.

**Mitigation factors**:
- `objc_getAssociatedObject` / `objc_setAssociatedObject` use an internal lock in the ObjC runtime (`AssociationsManager` mutex). Memory access is serialized at the runtime level.
- The value is wrapped in `Box<UInt>`. After reading the Box reference, we immediately extract the `UInt` value (copy semantics). No retained reference escapes.
- The same pattern already exists in `onShouldApply` for `ImageProgressiveProvider` (called from background decoder thread).

**Worst case of torn read**:
- Read old value (checker thinks task is still valid) → proceed with decode → same as current behavior
- Read new value (checker thinks task is stale) → skip a decode that was actually still needed → cell shows placeholder until the truly-current task completes

**Recommendation**: Consider changing `OBJC_ASSOCIATION_RETAIN_NONATOMIC` to `OBJC_ASSOCIATION_RETAIN` in a separate PR, independent of this optimization. This would make the contract explicit without affecting performance (associated object access is already locked).

### 6.2 Spurious `.imageNotExisting` Error Propagation

When a skipped task returns `.success(nil)`, it becomes `.imageNotExisting` upstream. This error flows through `handler` → `failCurrentSource` (line 352-383).

`failCurrentSource` checks:
1. `error.isTaskCancelled` (line 354) — **no**, this is a cache error, not a cancellation error. Won't short-circuit.
2. `error.isLowDataModeConstrained` (line 359) — **no**. Won't trigger low-data-mode fallback.
3. `retrievingContext.popAlternativeSource()` (line 369) — **if alternative sources are configured**, the next source will be tried.

**Impact**: If a user configures `alternativeSources`, a skipped task may trigger retrieval from the next alternative source. This retrieval result will be discarded at the view layer (stale `taskIdentifier`), but it wastes a network request or cache lookup.

**Severity**: Low. `alternativeSources` is a rarely-used feature. The wasted work is bounded (one alternative attempt that gets discarded). The exact same waste occurs today when a network download completes for a stale task.

**Possible future improvement**: Introduce a dedicated `CacheErrorReason.taskCancelled` case so that `failCurrentSource` short-circuits at line 354. This would require adding a case to the public `KingfisherError.CacheErrorReason` enum — a source-breaking change if users have exhaustive switches. Could be considered for the next major version.

### 6.3 Already-Running Decode Cannot Be Interrupted

Once `cacheSerializer.image(with:data:options:)` begins execution, it runs to completion. There is no mid-decode cancellation.

**Mitigating factor**: The `ioQueue` is serial. At most one decode runs at any time. The memory consumed by a single in-flight decode is bounded and manageable. The issue in #2495 is caused by **dozens** of decodes queuing up and running sequentially while their decoded images accumulate in memory — our check prevents the queue from growing unboundedly.

### 6.4 `loadDiskFileSynchronously` Mode

When `loadDiskFileSynchronously` is `true`, the loading queue is `.untouch` (caller's thread, typically main). In this case:

- CHECK 1 runs on the main thread synchronously — `taskIdentifier` was **just** set, so the check always passes.
- The disk read and decode run synchronously on the main thread, blocking the runloop. No opportunity for cell reuse.

**Impact**: No behavior change for synchronous mode. This is expected — synchronous mode is inherently non-cancellable.

### 6.5 Direct `KingfisherManager` / `ImageCache` API Users

Users who call `KingfisherManager.shared.retrieveImage(with:options:completionHandler:)` or `ImageCache.default.retrieveImage(forKey:...)` directly:

- `sourceTaskIdentifierChecker` is never set (it's only populated from the view extension path).
- All checks evaluate to `if let checker = nil` → skip → original behavior.

**Impact**: None. Full backward compatibility.

---

## 7. Summary

### What This Fix Achieves

- **Skips expensive deserialization** for disk-cached images when the requesting view has already moved on to a different image
- **Prevents spurious network downloads** when a cancelled cache lookup for a custom-processed image returns "not found"
- **Preserves the completion handler contract** — every `setImage` always results in exactly one completion callback

### What This Fix Does NOT Achieve

- Cannot interrupt a decode that is already in progress (inherent limitation of `CacheSerializer` protocol)
- Does not add a first-class cancellation API for cache lookups (would require public API changes)
- Does not address the `taskIdentifier` data race (pre-existing, should be fixed independently)
- Does not change the eager disk-to-memory promotion design (a larger architectural topic)

### Estimated Effectiveness

| Scrolling Speed | Decodes Prevented | Memory Pressure Reduction |
|----------------|-------------------|--------------------------|
| Fast (>10 cells/sec) | ~90-100% of stale decodes | Significant |
| Moderate (~5 cells/sec) | ~50-70% of stale decodes | Moderate |
| Slow (<2 cells/sec) | ~0% (but no pressure) | N/A |

---

## 8. Implementation Plan

### Step 1: Add `sourceTaskIdentifierChecker` to `KingfisherParsedOptionsInfo`

**File**: `Sources/General/KingfisherOptionsInfo.swift`
**Location**: Line 420, after `onDataReceived` (the other internal property)

Add:
```swift
var onDataReceived: [any DataReceivingSideEffect]? = nil
var sourceTaskIdentifierChecker: (@Sendable () -> Bool)? = nil  // NEW
```

This is an internal property (no `public` modifier), matching the pattern of `onDataReceived`. It does not need handling in the `init(_ info:)` switch since it is never set from `KingfisherOptionsInfoItem`.

**Verification**: Build succeeds. No public API surface change.

### Step 2: Store `referenceTaskIdentifierChecker` into options

**File**: `Sources/General/KingfisherManager.swift`
**Location**: Line 329-333, inside `retrieveImage(with:options:...referenceTaskIdentifierChecker:...)`

Change from:
```swift
if let checker = referenceTaskIdentifierChecker {
    options.onDataReceived?.forEach {
        $0.onShouldApply = checker
    }
}
```

To:
```swift
if let checker = referenceTaskIdentifierChecker {
    options.onDataReceived?.forEach {
        $0.onShouldApply = checker
    }
    options.sourceTaskIdentifierChecker = checker
}
```

This one-line addition causes the checker to propagate through `RetrievingContext.options` into every downstream call that receives `KingfisherParsedOptionsInfo`, including `ImageCache.retrieveImage` and `retrieveImageInDiskCache`.

**Verification**: Build succeeds. Existing tests pass — no behavioral change yet.

### Step 3: Insert cancellation checks in `retrieveImageInDiskCache`

**File**: `Sources/Cache/ImageCache.swift`
**Location**: Line 730-749, the `loadingQueue.execute` block in the internal `retrieveImageInDiskCache`

Change from:
```swift
loadingQueue.execute {
    do {
        var image: KFCrossPlatformImage? = nil
        if let data = try self.diskStorage.value(
            forKey: computedKey,
            forcedExtension: options.forcedExtension,
            extendingExpiration: options.diskCacheAccessExtendingExpiration
        ) {
            image = options.cacheSerializer.image(with: data, options: options)
        }
        if options.backgroundDecode {
            image = image?.kf.decoded(scale: options.scaleFactor)
        }
        callbackQueue.execute { [image] in completionHandler(.success(image)) }
    } catch let error as KingfisherError {
        callbackQueue.execute { completionHandler(.failure(error)) }
    } catch {
        assertionFailure("The internal thrown error should be a `KingfisherError`.")
    }
}
```

To:
```swift
loadingQueue.execute {
    // CHECK 1: For blocks queued behind others on the serial ioQueue,
    // the task is likely already stale by the time execution begins.
    if let checker = options.sourceTaskIdentifierChecker, !checker() {
        callbackQueue.execute { completionHandler(.success(nil)) }
        return
    }

    do {
        var image: KFCrossPlatformImage? = nil
        if let data = try self.diskStorage.value(
            forKey: computedKey,
            forcedExtension: options.forcedExtension,
            extendingExpiration: options.diskCacheAccessExtendingExpiration
        ) {
            // CHECK 2: Disk read completed, but deserialization has not started.
            // Catches staleness that occurred during a slow disk read.
            if let checker = options.sourceTaskIdentifierChecker, !checker() {
                callbackQueue.execute { completionHandler(.success(nil)) }
                return
            }
            image = options.cacheSerializer.image(with: data, options: options)
        }
        if options.backgroundDecode {
            image = image?.kf.decoded(scale: options.scaleFactor)
        }
        callbackQueue.execute { [image] in completionHandler(.success(image)) }
    } catch let error as KingfisherError {
        callbackQueue.execute { completionHandler(.failure(error)) }
    } catch {
        assertionFailure("The internal thrown error should be a `KingfisherError`.")
    }
}
```

**Why two checks**:
- CHECK 1 fires for queued blocks whose task became stale while waiting. Skips both disk I/O and decode. This is the high-hit-rate path during fast scrolling.
- CHECK 2 fires when disk read was slow (large file) and the task became stale during the read. Skips only decode.

**Verification**: Build succeeds. Test with a fast-scrolling collection view and Instruments to confirm decode skipping.

### Step 4: Prevent spurious download in `retrieveImageFromCache` path 2

**File**: `Sources/General/KingfisherManager.swift`
**Location**: Line 724-738, inside the `originalCache.retrieveImage` callback in `retrieveImageFromCache`

Change from:
```swift
result.match(
    onSuccess: { cacheResult in
        guard let image = cacheResult.image else {
            if options.onlyFromCache {
                let error = KingfisherError.cacheError(reason: .imageNotExisting(key: key))
                options.callbackQueue.execute { completionHandler?(.failure(error)) }
            } else {
                let task = self.loadAndCacheImage(
                    source: source,
                    context: context,
                    completionHandler: completionHandler
                )
                downloadTaskUpdated?(task?.value)
            }
            return
        }
```

To:
```swift
result.match(
    onSuccess: { cacheResult in
        guard let image = cacheResult.image else {
            // If the task is stale (cancelled by a newer setImage call),
            // report cache miss instead of triggering a network download.
            if let checker = options.sourceTaskIdentifierChecker, !checker() {
                let error = KingfisherError.cacheError(reason: .imageNotExisting(key: key))
                options.callbackQueue.execute { completionHandler?(.failure(error)) }
                return
            }

            if options.onlyFromCache {
                let error = KingfisherError.cacheError(reason: .imageNotExisting(key: key))
                options.callbackQueue.execute { completionHandler?(.failure(error)) }
            } else {
                let task = self.loadAndCacheImage(
                    source: source,
                    context: context,
                    completionHandler: completionHandler
                )
                downloadTaskUpdated?(task?.value)
            }
            return
        }
```

**Why this is needed**: Path 2 handles original-image fallback with custom processors. When the original image's decode is skipped (returning `.none`), the existing code falls through to `loadAndCacheImage`, triggering a network download. The check prevents this wasted request while still calling `completionHandler` to preserve the contract.

**Verification**: Build succeeds. Existing tests pass. For targeted testing: configure a custom `ImageProcessor` with disk-cached original images, fast-scroll, and verify no spurious network requests in Charles/Instruments.

### Step 5: Testing

#### Unit Tests

Add test cases in `Tests/KingfisherTests/`:

1. **Cache retrieval skip on stale identifier**: Set up a disk-cached image. Simulate a stale `sourceTaskIdentifierChecker` (returns `false`). Verify `retrieveImageInDiskCache` returns `.success(nil)` without invoking `CacheSerializer.image(with:)`.

2. **Completion handler contract**: Call `setImage`, then immediately call `setImage` again on the same view. Verify the first call's completion receives `.notCurrentSourceTask` error.

3. **Valid identifier proceeds normally**: Set up a disk-cached image. Provide a checker that returns `true`. Verify the image is decoded and returned normally.

4. **Path 2 download prevention**: Configure a custom processor, cache only the original image on disk. Provide a stale checker. Verify `loadAndCacheImage` is NOT called and completion receives `.imageNotExisting`.

#### Manual / Integration Testing

- **Instruments**: Profile a fast-scrolling collection view with WebP images. Compare memory peak before and after the change.
- **Functional**: Verify images display correctly at all scrolling speeds. No blank or stuck cells.
- **Edge cases**: Test with `loadDiskFileSynchronously = true`, `fromMemoryCacheOrRefresh = true`, and `alternativeSources` configured.

### Execution Order

```
Step 1 (add property)
  └─ Step 2 (wire checker into options)
       └─ Step 3 (cache-level checks)   ── can be done in parallel ──  Step 4 (path 2 guard)
                                                                           │
                                                                       Step 5 (tests)
```

Steps 1→2 are prerequisites. Steps 3 and 4 are independent of each other. Step 5 should cover all changes.

## Review From Codex

### Overall Assessment

I agree with the root cause analysis in this document:

- The main issue is not `cancelDownloadTask()` itself, but that the disk-cache retrieval path has no cancellation point once work is enqueued.
- The current disk-hit behavior eagerly deserializes the image and then promotes it into memory cache, even when the requesting view has already moved on to another source.
- The existing `taskIdentifier` check at the view layer happens too late. It prevents stale results from being applied to the view, but it does not prevent the expensive decode work from already happening.

These points are consistent with the current implementation in:

- `Sources/Extensions/ImageView+Kingfisher.swift`
- `Sources/General/KingfisherManager.swift`
- `Sources/Cache/ImageCache.swift`
- `Sources/Networking/ImageDownloader.swift`

### Main Concern With the Proposed Fix

I do **not** recommend shipping the proposed solution exactly as written.

The main problem is that it represents a stale request as `.success(nil)` inside `retrieveImageInDiskCache`, which then becomes a normal cache miss (`.none` / `.imageNotExisting`) upstream.

That encoding leaks the wrong semantics into higher layers:

- `ImageCache.retrieveImage(forKey:options:...)` treats `nil` as a normal disk miss.
- `KingfisherManager.retrieveImageFromCache` then treats that result as an ordinary cache failure path.
- At the manager level, ordinary failures can still flow into retry logic or `alternativeSources`.

So the side effect is broader than only "path 2 may trigger a spurious download". Both retry and alternative-source logic can be activated by a stale request that should have been short-circuited as "no longer relevant", not "cache miss".

This is the strongest reason I would not merge the current proposal unchanged.

### Thread-Safety Concern

The document's thread-safety discussion is somewhat optimistic.

Today, the checker closure reads `taskIdentifier` from a background queue, while writes happen on `@MainActor`. The storage behind `taskIdentifier` is implemented with associated objects and `OBJC_ASSOCIATION_RETAIN_NONATOMIC`.

Changing that association to atomic might reduce some risk, but it does not really solve the larger issue: a background queue is still observing UI-associated state across actor boundaries.

If this optimization is added, I suggest tightening this part of the design as well, instead of relying on the current associated-object pattern more heavily than it already is.

### Additional Observation

The proposed check points are directionally correct, but there is one more cheap place worth checking:

- after disk read
- before serializer decode
- before `backgroundDecode`

The dominant cost for WebP is likely already inside the serializer path, so this does not change the main conclusion. Still, adding a final stale check before `backgroundDecode` is nearly free and keeps the behavior more consistent.

### Recommended Direction

I recommend keeping the overall approach, but changing the internal representation of the outcome.

Instead of encoding "stale request" as `.success(nil)` or `.imageNotExisting`, use an explicit internal stale state, for example an internal retrieval result such as:

```swift
enum DiskRetrievalResult {
    case image(KFCrossPlatformImage)
    case none
    case stale
}
```

Then:

- `ImageCache` can stop work early and report `.stale` internally.
- `KingfisherManager` can short-circuit `.stale` without entering retry logic.
- `retrieveImageFromCache` path 2 can avoid download fallback for stale work.
- completion behavior at the view layer remains unchanged, because the view will still eventually surface `.notCurrentSourceTask` for the outdated request.

This preserves the optimization benefit without polluting existing cache-miss semantics.

### Recommended Checker Design

I would also prefer that the checker read from a dedicated thread-safe token holder instead of reading the view's associated-object-backed `taskIdentifier` directly from a background queue.

Using `sourceTaskIdentifierChecker` as an internal option is fine. The weak point is not the propagation mechanism; it is the current state source used by the checker.

### Memory-Model Note

This issue is primarily about avoiding stale decode work, and that is worth fixing first.

However, the current memory spike is amplified by another design choice as well: on disk hit, the decoded image is unconditionally promoted back into memory cache. If memory pressure reports continue even after stale decode skipping is added, the next place to revisit is whether disk-hit promotion should always be eager.

That is a larger architectural question and should probably remain separate from the narrow fix for #2495.

### Documentation Note

One minor accuracy issue in the implementation plan: the file name should be `Sources/General/KingfisherOptionsInfo.swift`, not `KingfisherOptionsInfoItems.swift`.

### Merge Recommendation

My recommendation is:

1. Keep the idea of checking staleness before expensive disk-cache deserialization.
2. Do not encode stale work as a normal cache miss.
3. Introduce an internal explicit stale outcome and short-circuit it in `KingfisherManager`.
4. Tighten the checker state source so it does not depend on reading UI-associated state from a background queue.
5. Add regression tests for retry strategy and `alternativeSources`, not only for path 2 fallback.

With those adjustments, the fix looks worthwhile and technically sound. Without them, the current proposal is likely to reduce memory pressure in the target scenario, but it also introduces semantic leakage into error handling and recovery paths.

## Response From Claude

### Overall

The Codex review is thorough and technically accurate. All five recommendations are accepted and should be incorporated into the final implementation.

### On the Main Concern (`.success(nil)` Semantic Leakage)

This is the most valuable point in the review, and it identifies a flaw that our original analysis underestimated.

Section 6.2 of this document assessed the `alternativeSources` interaction as "Low" severity. That assessment was incomplete. The retry strategy interaction is worse: a stale request encoded as `.imageNotExisting` enters `handler` (KingfisherManager.swift:394), which consults `retryStrategy`. If the user has configured a retry strategy (e.g., `DelayRetryStrategy(maxRetryCount: 3)`), the stale request loops through `startNewRetrieveTask` → `imageCachedType` (still cached) → `retrieveImage` → ioQueue → checker (still stale) → `.imageNotExisting` → retry again, up to `maxRetryCount` times. Each cycle is individually cheap (the checker skips decode), but the loop is semantically wrong and wastes work.

The `DiskRetrievalResult` enum approach cleanly eliminates this. By distinguishing `.stale` from `.none` at the `ImageCache` boundary, `KingfisherManager` can short-circuit before entering retry or alternative-source logic. The additional complexity is minimal (~10 lines for the enum + ~10 lines for handling), and it makes the control flow explicit and correct.

### On Thread Safety

The review correctly notes that our thread-safety discussion is optimistic. The practical risk is indeed low — `objc_getAssociatedObject` uses an internal runtime lock, and the `Box<UInt>` value is immediately copied — but "probably safe due to runtime implementation details" is not a strong engineering argument for a library consumed by thousands of apps.

More importantly, we are not introducing this pattern — the existing `onShouldApply` in `ImageProgressiveProvider` already reads `taskIdentifier` from a background thread. Our change would amplify the reliance on this pattern (every disk cache retrieval instead of only progressive loads), which makes the case for fixing it stronger.

A `CancellationToken` (~15 lines) replaces the cross-actor read with a lock-protected `Bool`. The checker becomes `{ !token.isCancelled }` instead of `{ issuedIdentifier == self.taskIdentifier }`. This is self-evidently correct and does not depend on ObjC runtime internals. It should be included in the initial PR rather than deferred, since the incremental cost is small and the design becomes clean from the start.

### On `backgroundDecode` Check

Agreed. `decoded(scale:)` forces bitmap rendering into a new context. The cost is secondary to WebP deserialization, but the check is nearly free and keeps the pattern consistent. Include it.

### On Regression Tests

The original test plan (Section 8, Step 5) covered the basic cases but missed two important scenarios:

1. **Retry strategy with stale request**: Verify that a stale disk cache retrieval does not enter the retry loop. With `DiskRetrievalResult.stale`, the handler should short-circuit before consulting `retryStrategy`.

2. **Alternative sources with stale request**: Verify that a stale result does not trigger `popAlternativeSource()`. The `.stale` result should bypass `failCurrentSource` entirely.

These should be added to the test plan.

### On the Documentation Note

Confirmed. Section 3.1 and the Summary table in Section 3 reference `KingfisherOptionsInfoItems.swift`. The correct file name is `KingfisherOptionsInfo.swift`. This will be corrected when the implementation plan is finalized.

### Summary of Accepted Changes

All five recommendations are accepted for the initial PR:

| # | Recommendation | Rationale | Additional Code |
|---|---------------|-----------|-----------------|
| 1 | Keep staleness checking before deserialization | Core optimization, already planned | 0 |
| 2 | Use `DiskRetrievalResult` instead of `.success(nil)` | Prevents semantic leakage into retry and alternative-source logic | ~10 lines |
| 3 | Short-circuit `.stale` in `KingfisherManager` | Avoids retry loops and spurious downloads for stale requests | ~10 lines |
| 4 | `CancellationToken` for thread-safe state | Eliminates cross-actor associated-object reads from ioQueue | ~15 lines |
| 5 | Regression tests for retry and `alternativeSources` | Covers the interaction that the original test plan missed | Test code |

Total additional production code over the original proposal: ~35 lines. The overall change remains small and focused.
