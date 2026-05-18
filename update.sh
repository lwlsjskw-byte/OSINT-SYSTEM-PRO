#!/bin/bash

echo "🚀 Updating GitHub..."

git add .

git commit -m "auto update $(date)"

git push

echo "✅ Done!"
