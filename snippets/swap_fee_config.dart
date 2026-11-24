// Excerpt from SuperWallet (crypto_wallet/lib/core/monetization/swap_fee_config.dart). Shown for illustration only. The full source code is available at https://store.mikodes.com/p/superwallet/
//
// The operator's swap fee is off by default and hard-capped at 2 % (200 bps).
// Every value is clamped when it is built and again when it is read, so a
// mistyped admin setting can never overcharge a user.

/// Configuration for platform swap fees applied to all routed swaps.
///
/// When [enabled] is true, the fee parameters are appended to quote requests
/// for Jupiter (Solana), 0x Protocol (EVM), and 1inch (EVM) so that the
/// platform wallet [feeWalletAddress] receives a share of each swap.
///
/// All values are loaded at runtime from the remote AdminConfig / feature-flag
/// system; in-code defaults are always disabled (fee = 0).
class SwapFeeConfig {
  /// Hard cap on the operator fee: 200 bps (2 %). Every aggregator path
  /// (Jupiter, 0x, 1inch) reads the fee through [feeBps] / [feePercent], which
  /// both clamp to this cap, so a mis-typed admin value can never overcharge.
  static const int maxFeeBps = 200;

  /// [maxFeeBps] as a fraction (0.02).
  static const double maxFeePercent = maxFeeBps / 10000.0;
  static const String productionPlaceholder =
      '__SET_PRODUCTION_FEE_WALLET_ADDRESS__';

  /// Fraction of each swap that flows to the platform wallet (0.0–1.0).
  ///
  /// Example: 0.003 = 0.3 %.  Stored as a fraction, not a percentage.
  /// Always clamped to [0, maxFeePercent] when read.
  double get feePercent => _feePercent.isNaN
      ? 0.0
      : _feePercent.clamp(0.0, maxFeePercent).toDouble();
  final double _feePercent;


  // … wallet addresses, per-chain overrides and the remaining fields are cut.
  final bool enabled;
  final String feeWalletAddress;
  final String solanaFeeWalletAddress;
  final Map<String, String> feeWalletAddressesByChain;

  const SwapFeeConfig({
    required double feePercent,
    required this.feeWalletAddress,
    required this.enabled,
    this.feeWalletAddressesByChain = const <String, String>{},
    this.solanaFeeWalletAddress = '',
  }) : _feePercent = feePercent;

  /// Safe default: fees are off.
  const SwapFeeConfig.disabled()
      : _feePercent = 0,
        feeWalletAddress = '',
        solanaFeeWalletAddress = '',
        feeWalletAddressesByChain = const <String, String>{},
        enabled = false;

  /// Creates a validated config from raw values.
  ///
  /// [feePercent] is clamped to [0, maxFeePercent].
  factory SwapFeeConfig.fromValues({
    required double feePercent,
    required String feeWalletAddress,
    required bool enabled,
    Map<String, String> feeWalletAddressesByChain = const <String, String>{},
    String solanaFeeWalletAddress = '',
  }) {
    return SwapFeeConfig(
      solanaFeeWalletAddress: solanaFeeWalletAddress.trim(),
      feePercent: feePercent.isNaN
          ? 0.0
          : feePercent.clamp(0.0, maxFeePercent).toDouble(),
      feeWalletAddress: feeWalletAddress.trim(),
      enabled: enabled,
      feeWalletAddressesByChain: Map<String, String>.unmodifiable(
        feeWalletAddressesByChain.map(
          (key, value) => MapEntry(key.trim(), value.trim()),
        )..removeWhere((key, value) => key.isEmpty || value.isEmpty),
      ),
    );
  }

  /// Creates config from an [AdminConfigModel]-shaped map entry.
  ///
}
