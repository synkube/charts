#!/bin/bash

# Shared Helm chart test renderer
# Usage: ./test-render.sh <chart-path>

# No strict error handling - following generic-app pattern

# Check if chart path is provided
if [ $# -eq 0 ]; then
  echo "❌ Error: Chart path is required"
  echo "Usage: $0 <chart-path>"
  echo "Example: $0 charts/app-extensions"
  exit 1
fi

CHART_PATH="$1"
CHART_NAME=$(basename "$CHART_PATH")

# Validate chart path
if [ ! -d "$CHART_PATH" ]; then
  echo "❌ Error: Chart directory not found at $CHART_PATH"
  exit 1
fi

if [ ! -f "$CHART_PATH/Chart.yaml" ]; then
  echo "❌ Error: Chart.yaml not found in $CHART_PATH"
  exit 1
fi

# Initialize counters
passed=0
failed=0

# Create .test-output directory if it doesn't exist
OUTPUT_DIR="$CHART_PATH/.test-output"
mkdir -p "$OUTPUT_DIR"

# Cleanup function
cleanup() {
  # Optional: Remove test output files
  # rm -rf "$OUTPUT_DIR"
  true
}

# Register cleanup on exit
trap cleanup EXIT

echo "================================"
echo "Testing $CHART_NAME Chart"
echo "================================"
echo

# Find all test value files
TEST_VALUES_DIR="$CHART_PATH/test-values"
if [ ! -d "$TEST_VALUES_DIR" ]; then
  echo "❌ Error: test-values directory not found at $TEST_VALUES_DIR"
  exit 1
fi

# Get all yaml files in test-values directory
test_files=($(find "$TEST_VALUES_DIR" -name "*.yaml" -o -name "*.yml" | sort))

if [ ${#test_files[@]} -eq 0 ]; then
  echo "⚠️  Warning: No test value files found in $TEST_VALUES_DIR"
  exit 0
fi

echo "Found ${#test_files[@]} test value file(s)"
echo

# Test each value file
for test_file in "${test_files[@]}"; do
  filename=$(basename "$test_file")
  test_name="${filename%.*}"  # Remove extension
  output_file="$OUTPUT_DIR/output-$test_name.yaml"

  echo "-----------------------------------"
  echo "Test: $test_name"
  echo "File: $filename"
  echo "-----------------------------------"

  # Check if cluster is available
  if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null 2>&1; then
    # With cluster: use helm install --dry-run=server (real capabilities + server-side validation)
    if helm install "test-$test_name" "$CHART_PATH" -f "$test_file" --dry-run=server > "$output_file" 2>&1; then
      resource_count=$(grep "^kind:" "$output_file" 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")
      if [ "$resource_count" -gt 0 ]; then
        echo "✓ Helm install --dry-run=server: SUCCESS ($resource_count resource(s))"
        echo "  Resources:"
        grep "^kind:" "$output_file" | sort | uniq -c | sed 's/^/    /' || true
        ((passed++))
      else
        echo "⚠️  WARNING - No Kubernetes resources generated"
        ((passed++))
      fi
    else
      echo "✗ FAILED - Helm install --dry-run=server failed"
      echo "  Error output:"
      tail -15 "$output_file" | sed 's/^/    /'
      ((failed++))
    fi
  else
    # Without cluster: use helm template with skipApiCheck to render all resources
    if helm template "test-$test_name" "$CHART_PATH" -f "$test_file" --set global.skipApiCheck=true > "$output_file" 2>&1; then
      resource_count=$(grep "^kind:" "$output_file" 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")
      if [ "$resource_count" -gt 0 ]; then
        echo "✓ Helm template: SUCCESS ($resource_count resource(s))"
        echo "  Resources:"
        grep "^kind:" "$output_file" | sort | uniq -c | sed 's/^/    /' || true
        echo "ℹ️  Kubernetes validation: SKIPPED (no cluster access)"
        ((passed++))
      else
        echo "⚠️  WARNING - No Kubernetes resources generated"
        ((passed++))
      fi
    else
      echo "✗ FAILED - Helm template rendering failed"
      echo "  Error output:"
      tail -15 "$output_file" | sed 's/^/    /'
      ((failed++))
    fi
  fi

  echo
done

# Print summary
echo "================================"
echo "Test Summary"
echo "================================"
echo "Total tests: ${#test_files[@]}"
echo "Passed: $passed"
echo "Failed: $failed"
echo

if [ "$failed" -eq 0 ]; then
  echo "🎉 All tests passed!"
  exit 0
else
  echo "❌ $failed test(s) failed"
  exit 1
fi
