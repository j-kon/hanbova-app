#!/usr/bin/env bash
set -euo pipefail

# Script: build_ios_ffi.sh
# Purpose: Compiles the Rust CDK FFI library for iOS targets (Device + Universal Simulator)
#          and packages a universal static framework into ios/Frameworks/HanbovaCdkFfi.xcframework

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MONOREPO_ROOT="$(cd "${APP_DIR}/.." && pwd)"
BACKEND_DIR="${MONOREPO_ROOT}/hanbova-backend"
CRATE_DIR="${BACKEND_DIR}/crates/hanbova-cdk-ffi"
OUTPUT_FRAMEWORKS_DIR="${APP_DIR}/ios/Frameworks"
TEMP_DIR="${APP_DIR}/ios/build_temp"

echo "============================================================"
echo " Building Hanbova CDK FFI XCFramework for iOS"
echo " Backend Crate: ${CRATE_DIR}"
echo " Output Dir:    ${OUTPUT_FRAMEWORKS_DIR}"
echo "============================================================"

# Ensure rustup targets are installed
echo "Ensuring required iOS Rust targets are installed..."
rustup target add aarch64-apple-ios
rustup target add aarch64-apple-ios-sim
rustup target add x86_64-apple-ios

# Build release targets
echo "Building aarch64-apple-ios (Physical Device ARM64)..."
cargo build --manifest-path "${BACKEND_DIR}/Cargo.toml" --package hanbova-cdk-ffi --release --target aarch64-apple-ios

echo "Building aarch64-apple-ios-sim (Simulator ARM64)..."
cargo build --manifest-path "${BACKEND_DIR}/Cargo.toml" --package hanbova-cdk-ffi --release --target aarch64-apple-ios-sim

echo "Building x86_64-apple-ios (Simulator x86_64)..."
cargo build --manifest-path "${BACKEND_DIR}/Cargo.toml" --package hanbova-cdk-ffi --release --target x86_64-apple-ios

# Prepare Headers & Modulemap
mkdir -p "${CRATE_DIR}/include"
cat << 'EOF' > "${CRATE_DIR}/include/hanbova_cdk_ffi.h"
#ifndef HANBOVA_CDK_FFI_H
#define HANBOVA_CDK_FFI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CdkWalletHandle CdkWalletHandle;

char* hanbova_cdk_get_last_error(void);
void hanbova_cdk_free_string(char* s);

int hanbova_cdk_wallet_create(
    const char* mint_url,
    const char* db_path,
    const char* seed_hex,
    CdkWalletHandle** out_handle
);

int hanbova_cdk_wallet_get_balance(
    CdkWalletHandle* handle,
    uint64_t* out_spendable,
    uint64_t* out_pending
);

int hanbova_cdk_mint_quote(
    CdkWalletHandle* handle,
    uint64_t amount,
    char** out_quote_id,
    char** out_invoice
);

int hanbova_cdk_check_mint_quote_status(
    CdkWalletHandle* handle,
    const char* quote_id,
    char** out_state,
    int* out_paid
);

int hanbova_cdk_mint(
    CdkWalletHandle* handle,
    const char* quote_id,
    uint64_t* out_minted_amount
);

int hanbova_cdk_melt_quote(
    CdkWalletHandle* handle,
    const char* invoice,
    char** out_quote_id,
    uint64_t* out_amount_sats,
    uint64_t* out_fee_reserve_sats
);

int hanbova_cdk_melt(
    CdkWalletHandle* handle,
    const char* quote_id,
    int* out_paid,
    char** out_preimage
);

int hanbova_cdk_prepare_p2pk_send(
    CdkWalletHandle* handle,
    uint64_t amount,
    const char* recipient_pubkey_hex,
    const char* refund_pubkey_hex,
    uint64_t locktime_unix,
    char** out_token
);

int hanbova_cdk_receive_p2pk(
    CdkWalletHandle* handle,
    const char* token,
    const char* p2pk_privkey_hex,
    uint64_t* out_received_amount
);

int hanbova_cdk_check_token_state(
    CdkWalletHandle* handle,
    const char* token,
    int* out_is_spent
);

void hanbova_cdk_wallet_free(CdkWalletHandle* handle);

#ifdef __cplusplus
}
#endif

#endif /* HANBOVA_CDK_FFI_H */
EOF

cat << 'EOF' > "${CRATE_DIR}/include/module.modulemap"
framework module HanbovaCdkFfi {
  umbrella header "hanbova_cdk_ffi.h"
  export *
  module * { export * }
}
EOF

cat << 'EOF' > "${CRATE_DIR}/include/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>HanbovaCdkFfi</string>
	<key>CFBundleIdentifier</key>
	<string>org.hanbova.HanbovaCdkFfi</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>HanbovaCdkFfi</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>0.1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
</dict>
</plist>
EOF

# Build static framework directories
rm -rf "${TEMP_DIR}"
mkdir -p "${TEMP_DIR}/ios-arm64/HanbovaCdkFfi.framework/Headers"
mkdir -p "${TEMP_DIR}/ios-arm64/HanbovaCdkFfi.framework/Modules"
mkdir -p "${TEMP_DIR}/ios-sim/HanbovaCdkFfi.framework/Headers"
mkdir -p "${TEMP_DIR}/ios-sim/HanbovaCdkFfi.framework/Modules"

cp "${BACKEND_DIR}/target/aarch64-apple-ios/release/libhanbova_cdk_ffi.a" "${TEMP_DIR}/ios-arm64/HanbovaCdkFfi.framework/HanbovaCdkFfi"
cp "${CRATE_DIR}/include/hanbova_cdk_ffi.h" "${TEMP_DIR}/ios-arm64/HanbovaCdkFfi.framework/Headers/"
cp "${CRATE_DIR}/include/module.modulemap" "${TEMP_DIR}/ios-arm64/HanbovaCdkFfi.framework/Modules/"
cp "${CRATE_DIR}/include/Info.plist" "${TEMP_DIR}/ios-arm64/HanbovaCdkFfi.framework/Info.plist"

# Create universal simulator binary combining arm64-sim and x86_64-sim
lipo -create \
  "${BACKEND_DIR}/target/aarch64-apple-ios-sim/release/libhanbova_cdk_ffi.a" \
  "${BACKEND_DIR}/target/x86_64-apple-ios/release/libhanbova_cdk_ffi.a" \
  -output "${TEMP_DIR}/ios-sim/HanbovaCdkFfi.framework/HanbovaCdkFfi"

cp "${CRATE_DIR}/include/hanbova_cdk_ffi.h" "${TEMP_DIR}/ios-sim/HanbovaCdkFfi.framework/Headers/"
cp "${CRATE_DIR}/include/module.modulemap" "${TEMP_DIR}/ios-sim/HanbovaCdkFfi.framework/Modules/"
cp "${CRATE_DIR}/include/Info.plist" "${TEMP_DIR}/ios-sim/HanbovaCdkFfi.framework/Info.plist"

# Package XCFramework
echo "Packaging HanbovaCdkFfi.xcframework..."
rm -rf "${OUTPUT_FRAMEWORKS_DIR}/HanbovaCdkFfi.xcframework"
mkdir -p "${OUTPUT_FRAMEWORKS_DIR}"

xcodebuild -create-xcframework \
  -framework "${TEMP_DIR}/ios-arm64/HanbovaCdkFfi.framework" \
  -framework "${TEMP_DIR}/ios-sim/HanbovaCdkFfi.framework" \
  -output "${OUTPUT_FRAMEWORKS_DIR}/HanbovaCdkFfi.xcframework"

rm -rf "${TEMP_DIR}"

echo "============================================================"
echo " Universal XCFramework successfully built at:"
echo " ${OUTPUT_FRAMEWORKS_DIR}/HanbovaCdkFfi.xcframework"
echo "============================================================"
