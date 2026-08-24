#include "hanbova_cdk_ffi.h"
#include <stddef.h>

// Force-link references to prevent the linker from dead-stripping any CDK C-FFI symbols
__attribute__((used)) void __hanbova_cdk_ffi_retain_symbols(void) {
    (void)hanbova_cdk_get_last_error();
    hanbova_cdk_free_string(NULL);
    (void)hanbova_cdk_wallet_create(NULL, NULL, NULL, NULL);
    (void)hanbova_cdk_wallet_get_balance(NULL, NULL, NULL);
    (void)hanbova_cdk_mint_quote(NULL, 0, NULL, NULL);
    (void)hanbova_cdk_mint(NULL, NULL, NULL);
    (void)hanbova_cdk_prepare_p2pk_send(NULL, 0, NULL, NULL, 0, NULL);
    (void)hanbova_cdk_receive_p2pk(NULL, NULL, NULL, NULL);
    (void)hanbova_cdk_check_token_state(NULL, NULL, NULL);
    hanbova_cdk_wallet_free(NULL);
}
