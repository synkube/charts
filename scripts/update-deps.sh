#!/bin/bash
set -euo pipefail

# Update dependencies for all charts efficiently
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
        echo "🔧 Building dependencies for $chart_name (no repo refresh)"
        cd "$chart_dir"
        helm dependency build --skip-refresh
        cd - > /dev/null
    else
        echo "ℹ️  No dependencies found for $chart_name"
    fi
done

echo ""
echo "✅ All chart dependencies updated efficiently!"
