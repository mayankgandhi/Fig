#!/bin/sh

echo "🔧 Starting Xcode Cloud setup..."

# Skip macro fingerprint validation first
echo "⚙️  Configuring Xcode settings..."
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES || {
    echo "❌ Failed to configure Xcode settings"
    exit 1
}

# Install mise
echo "📦 Installing mise..."
curl https://mise.run | sh || {
    echo "❌ Failed to install mise"
    exit 1
}

# Add mise to PATH
export PATH="$HOME/.local/bin:$PATH"

# Verify mise installation
echo "🔍 Verifying mise installation..."
if [ -f "$HOME/.local/bin/mise" ]; then
    echo "✅ mise binary found"
else
    echo "❌ mise binary not found"
    exit 1
fi

# Install tuist via mise
echo "🛠️  Installing tuist..."
$HOME/.local/bin/mise install tuist || {
    echo "❌ Failed to install tuist"
    exit 1
}

# Use tuist globally
echo "🌍 Setting tuist globally..."
$HOME/.local/bin/mise use -g tuist || {
    echo "❌ Failed to set tuist globally"
    exit 1
}

# Skip activation - use direct mise exec instead
echo "🔍 Verifying tuist installation via mise..."
$HOME/.local/bin/mise exec -- tuist version || {
    echo "❌ tuist not accessible via mise"
    exit 1
}

# Install tuist dependencies using direct mise exec
echo "📥 Installing tuist dependencies..."
$HOME/.local/bin/mise exec -- tuist install || {
    echo "❌ Failed to install tuist dependencies"
    exit 1
}

cd ..
# Generate the project using direct mise exec
echo "🏗️  Generating Xcode project..."
$HOME/.local/bin/mise exec -- tuist generate || {
    echo "❌ Failed to generate Xcode project"
    exit 1
}

echo "✅ Setup complete!"