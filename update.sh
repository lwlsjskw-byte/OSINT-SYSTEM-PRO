#!/bin/bash

echo "🚀 Updating GitHub..."

git add .

git commit -m "auto update $(date)"

git push

if [ $? -eq 0 ]; then
    echo "✅ Push success!"
else
    echo "❌ Push failed!"
fi
