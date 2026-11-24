// Excerpt from SuperWallet (lib/core/security/signing_auth_gate.dart). Shown for illustration only.
// The full source code is available at https://store.mikodes.com/p/superwallet/
//
// A short-lived grant for signing. One authentication can cover the signatures of one
// action (for example an approval followed by a swap) for at most 60 seconds, and
// dApp requests always ask again. With no authenticator attached it fails closed.

class SigningAuthGate {
  /// The longest time a grant stays open, even with uses left.
  static const Duration grantWindow = Duration(seconds: 60);

  SigningAuthenticator? _authenticator;
  DateTime? _grantUntil;
  int _usesLeft = 0;
  // …
  bool get hasGrant {
    final until = _grantUntil;
    return _usesLeft > 0 && until != null && clock().isBefore(until);
  }

  /// Closes any open grant.
  void revoke() {
    _grantUntil = null;
    _usesLeft = 0;
  }

  void _open(int uses) {
    _usesLeft = uses;
    _grantUntil = clock().add(grantWindow);
  }

  /// Starts one signing action that will make [uses] signatures.
  ///
  /// Replaces any grant that is still open. Returns whether the action may
  /// sign.
  Future<bool> authorize({
    required double? usdValue,
    required String reason,
    bool forceAuthentication = false,
    int uses = 1,
  }) async {
    assert(uses >= 1, 'an action signs at least once');
    revoke();
    if (!forceAuthentication && !requiresSigningReauth(usdValue)) {
      _open(uses);
      return true;
    }
    final ok = await _authenticate(reason);
    if (ok) {
      _open(uses);
    }
    return ok;
  }

  /// Called before every signature. Consumes one use of an open grant, or
  /// authenticates when there is none (or when [fresh] is true). Throws
  /// [SigningAuthRequiredException] when the user does not authenticate.
  Future<void> ensure(String reason, {bool fresh = false}) async {
    if (!fresh && hasGrant) {
      _usesLeft--;
      if (_usesLeft <= 0) {
        revoke();
      }
      return;
    }
    if (!await _authenticate(reason)) {
      throw const SigningAuthRequiredException();
    }
  }

  Future<bool> _authenticate(String reason) async {
    final authenticator = _authenticator;
    if (authenticator == null) {
      // Fail closed: nothing may sign before the wallet is set up.
      return false;
    }
    return authenticator(reason);
  }
}
