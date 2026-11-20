/// Shared rendering constants and thresholds for the particle network painter.
library;

/// Threshold particle count below which individual line drawing is used
/// instead of alpha-bucketed batch rendering.
const int kBatchThreshold = 30;

/// Number of discrete alpha buckets used for line opacity quantization.
const int kAlphaBucketCount = 32;

/// Table size for precomputed distance-squared to alpha bucket lookup.
const int kDistBucketTableSize = 1024;

/// Fallback line distance when non-positive distance is configured.
const double kFallbackLineDistance = 100.0;

/// Exponent applied to line-count ratio during dynamic budget feedback correction.
const double kBudgetCorrectionExponent = 0.25;

/// Minimum clamp for dynamic line budget correction multiplier.
const double kMinBudgetCorrection = 0.2;

/// Maximum clamp for dynamic line budget correction multiplier.
const double kMaxBudgetCorrection = 5.0;

/// Ratio of candidate checks to accepted pairs above which a cluster is considered dense.
const double kDenseRatioThreshold = 10.0;

/// Minimum particle count for dense cluster reduction to activate.
const int kDenseParticleThreshold = 500;

/// Divisor for connection distance to classify dense neighborhood in batched mode.
const double kDefaultDenseDivisor = 1.0 / 0.60;

/// Divisor for connection distance to classify dense neighborhood in individual mode.
const double kIndividualDenseDivisor = 1.5;

/// Default target complex lines in individual mode.
const int kDefaultMaxComplexLinesIndividual = 3;

/// Default target complex lines in batched mode.
const int kDefaultMaxComplexLinesBatched = 5;

/// Minimum particle count below which particles are drawn as individual circles.
const int kMinParticleBatchThreshold = 5;

/// Number of discrete particle size buckets for batched drawRawPoints.
const int kMaxParticleSizeBuckets = 64;
