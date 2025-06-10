#!/bin/bash

# Script to add handleRequestFromGo export to compiled Elm JavaScript

if [ ! -f "elm-handler.js" ]; then
    echo "❌ elm-handler.js not found!"
    exit 1
fi

# Check if the export is already there
if grep -q "handleRequestFromGo.*\$author\$project\$GoMain\$handleRequestFromGo" elm-handler.js; then
    echo "📦 Export already exists, skipping..."
    exit 0
fi

# Find the export line and add our function
sed -i '' 's/\$elm\$json\$Json\$Decode\$succeed(0))(0)}});/\$elm\$json\$Json\$Decode\$succeed(0))(0), '\''handleRequestFromGo'\'': \$author\$project\$GoMain\$handleRequestFromGo}});/g' elm-handler.js

# Verify the export was added
if grep -q "handleRequestFromGo.*\$author\$project\$GoMain\$handleRequestFromGo" elm-handler.js; then
    echo "✅ Successfully added handleRequestFromGo export"
else
    echo "❌ Failed to add export - check the pattern"
    exit 1
fi