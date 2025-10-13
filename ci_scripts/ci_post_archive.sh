#!/bin/sh

echo "🧹 Starting post-archive cleanup..."

# Kill any remaining mise processes
echo "🔄 Terminating mise processes..."
pkill -f mise || echo "ℹ️  No mise processes found"

# Kill any remaining tuist processes
echo "🔄 Terminating tuist processes..."
pkill -f tuist || echo "ℹ️  No tuist processes found"

# Clean up any background jobs
echo "🔄 Terminating background jobs..."
jobs -p | xargs -r kill 2>/dev/null || echo "ℹ️  No background jobs found"

# Force cleanup of any hanging processes related to our tools
echo "🔄 Cleaning up tool processes..."
ps aux | grep -E "(mise|tuist)" | grep -v grep | awk '{print $2}' | xargs -r kill -9 2>/dev/null || echo "ℹ️  No tool processes found"

echo "✅ Post-archive cleanup complete!"
exit 0