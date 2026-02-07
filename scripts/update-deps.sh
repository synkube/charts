#!/bin/bash
set -euo pipefail

# Update dependencies for all charts.
# Uses 'helm dependency update' so Chart.lock stays in sync with Chart.yaml.
# After changing dependencies in Chart.yaml, run this script and commit Chart.lock.

echo "🔄 Updating dependencies for all charts..."

# Update helm repositories once
echo ""
echo "📡 Updating Helm repository indexes..."
# helm repo update || echo "ℹ️  No repositories configured, continuing..."

echo ""
echo "📋 Processing chart dependencies..."

for chart_dir in charts/*/; do
    if [ ! -d "$chart_dir" ]; then
        continue
    fi

    chart_name=$(basename "$chart_dir")
    echo ""
    echo "📦 Processing: $chart_name"

    if [ -f "$chart_dir/Chart.yaml" ] && grep -q "dependencies:" "$chart_dir/Chart.yaml"; then
        echo "🔧 Updating dependencies for $chart_name (resyncs Chart.lock)"
        (cd "$chart_dir" && helm dependency update --skip-refresh)
    else
        echo "ℹ️  No dependencies found for $chart_name"
    fi
done

echo ""
echo "✅ All chart dependencies updated. Commit any changed Chart.lock files."
