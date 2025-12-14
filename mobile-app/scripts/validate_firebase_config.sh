#!/bin/bash
# Firebase Configuration Validation Script
#
# This script validates that Firebase configuration files are present and
# appear to be correctly formatted before building the app.
# Use in CI/CD pipelines to fail fast on missing or invalid configs.
#
# Usage: ./scripts/validate_firebase_config.sh [ios|android|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((warnings++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((errors++))
}

# Validate iOS configuration
validate_ios() {
    echo ""
    echo "📱 Validating iOS Firebase Configuration..."
    echo "================================================"
    
    local plist_path="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist"
    
    # Check if plist exists
    if [[ ! -f "$plist_path" ]]; then
        log_error "GoogleService-Info.plist not found at: $plist_path"
        echo "    Please download it from Firebase Console and add to ios/Runner/"
        return
    fi
    log_success "GoogleService-Info.plist exists"
    
    # Validate required keys in plist
    local required_keys=("GOOGLE_APP_ID" "BUNDLE_ID" "PROJECT_ID" "API_KEY" "GCM_SENDER_ID")
    for key in "${required_keys[@]}"; do
        if ! grep -q "<key>$key</key>" "$plist_path"; then
            log_error "Missing required key in plist: $key"
        fi
    done
    
    # Extract and validate GOOGLE_APP_ID format
    local app_id=$(grep -A1 "<key>GOOGLE_APP_ID</key>" "$plist_path" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    if [[ ! "$app_id" =~ ^1:[0-9]+:ios:[a-f0-9]+$ ]]; then
        log_error "Invalid GOOGLE_APP_ID format: $app_id"
        echo "    Expected format: 1:PROJECT_NUMBER:ios:HEX_ID"
    else
        log_success "GOOGLE_APP_ID format is valid: $app_id"
    fi
    
    # Extract BUNDLE_ID
    local bundle_id=$(grep -A1 "<key>BUNDLE_ID</key>" "$plist_path" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    log_success "BUNDLE_ID: $bundle_id"
    
    # Check firebase_options.dart iOS config
    local options_path="$PROJECT_ROOT/lib/firebase_options.dart"
    if [[ -f "$options_path" ]]; then
        # Check if iOS appId in options matches plist
        if grep -q "appId: '$app_id'" "$options_path" || grep -q "appId: \"$app_id\"" "$options_path"; then
            log_success "firebase_options.dart iOS appId matches plist"
        else
            log_warning "firebase_options.dart iOS appId may not match GoogleService-Info.plist"
            echo "    Plist GOOGLE_APP_ID: $app_id"
            echo "    Ensure firebase_options.dart ios.appId uses this value"
        fi
    fi
    
    # Check AppDelegate.swift
    local appdelegate_path="$PROJECT_ROOT/ios/Runner/AppDelegate.swift"
    if [[ -f "$appdelegate_path" ]]; then
        if grep -q "import FirebaseCore" "$appdelegate_path"; then
            log_success "AppDelegate.swift imports FirebaseCore"
        else
            log_error "AppDelegate.swift missing 'import FirebaseCore'"
        fi
        
        if grep -q "FirebaseApp.configure()" "$appdelegate_path"; then
            log_success "AppDelegate.swift calls FirebaseApp.configure()"
        else
            log_warning "AppDelegate.swift may not call FirebaseApp.configure()"
        fi
    else
        log_error "AppDelegate.swift not found"
    fi
}

# Validate Android configuration
validate_android() {
    echo ""
    echo "🤖 Validating Android Firebase Configuration..."
    echo "================================================"
    
    local json_path="$PROJECT_ROOT/android/app/google-services.json"
    local options_path="$PROJECT_ROOT/lib/firebase_options.dart"
    
    # Check if google-services.json exists (optional if using firebase_options.dart only)
    if [[ -f "$json_path" ]]; then
        log_success "google-services.json exists"
        
        # Validate it's valid JSON
        if command -v python3 &> /dev/null; then
            if python3 -c "import json; json.load(open('$json_path'))" 2>/dev/null; then
                log_success "google-services.json is valid JSON"
            else
                log_error "google-services.json is not valid JSON"
            fi
        fi
    else
        log_warning "google-services.json not found (using firebase_options.dart only)"
        echo "    This is OK if Firebase is configured via firebase_options.dart"
    fi
    
    # Check firebase_options.dart android config
    if [[ -f "$options_path" ]]; then
        log_success "firebase_options.dart exists"
        
        # Check Android appId format
        if grep -q "android.*appId.*1:[0-9]*:android:[a-f0-9]*" "$options_path"; then
            log_success "firebase_options.dart Android appId format appears valid"
        else
            log_warning "Could not verify Android appId format in firebase_options.dart"
        fi
    else
        log_error "firebase_options.dart not found"
    fi
    
    # Check build.gradle for Firebase dependencies
    local gradle_path="$PROJECT_ROOT/android/app/build.gradle.kts"
    if [[ -f "$gradle_path" ]]; then
        if grep -q "firebase-bom" "$gradle_path"; then
            log_success "Firebase BOM dependency found in build.gradle.kts"
        else
            log_warning "Firebase BOM not found in build.gradle.kts"
        fi
    fi
}

# Validate flutter options file
validate_options() {
    echo ""
    echo "🎯 Validating firebase_options.dart..."
    echo "================================================"
    
    local options_path="$PROJECT_ROOT/lib/firebase_options.dart"
    
    if [[ ! -f "$options_path" ]]; then
        log_error "firebase_options.dart not found at: $options_path"
        return
    fi
    
    log_success "firebase_options.dart exists"
    
    # Check for platform configurations
    for platform in "android" "ios" "web"; do
        if grep -q "static const FirebaseOptions $platform" "$options_path"; then
            log_success "$platform configuration found"
        else
            log_warning "$platform configuration not found"
        fi
    done
}

# Main
echo "🔥 Firebase Configuration Validator"
echo "===================================="
echo "Project root: $PROJECT_ROOT"

target="${1:-all}"

case "$target" in
    ios)
        validate_ios
        validate_options
        ;;
    android)
        validate_android
        validate_options
        ;;
    all)
        validate_ios
        validate_android
        validate_options
        ;;
    *)
        echo "Usage: $0 [ios|android|all]"
        exit 1
        ;;
esac

echo ""
echo "================================================"
echo "Validation Summary"
echo "================================================"
echo -e "Errors:   ${errors}"
echo -e "Warnings: ${warnings}"

if [[ $errors -gt 0 ]]; then
    echo ""
    log_error "Validation FAILED with $errors error(s)"
    exit 1
else
    echo ""
    log_success "Validation PASSED"
    if [[ $warnings -gt 0 ]]; then
        echo -e "${YELLOW}Note: $warnings warning(s) found - review recommended${NC}"
    fi
    exit 0
fi
