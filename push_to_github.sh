#!/bin/bash

# 🚀 LovedOnes GitHub Push Script
# This script helps you push your hackathon project to GitHub

echo "🏆 LovedOnes - AI-Powered Alzheimer's Care Platform"
echo "=================================================="
echo ""

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "❌ Git repository not initialized. Please run 'git init' first."
    exit 1
fi

# Check if we have commits
if [ -z "$(git log --oneline 2>/dev/null)" ]; then
    echo "❌ No commits found. Please commit your changes first."
    exit 1
fi

echo "✅ Git repository is ready"
echo ""

# Get GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ GitHub username is required"
    exit 1
fi

# Set up remote
echo "🔗 Setting up GitHub remote..."
git remote add origin https://github.com/$GITHUB_USERNAME/lovedones.git 2>/dev/null || git remote set-url origin https://github.com/$GITHUB_USERNAME/lovedones.git

# Push to GitHub
echo "📤 Pushing to GitHub..."
git branch -M main
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Successfully pushed to GitHub!"
    echo "🔗 Repository URL: https://github.com/$GITHUB_USERNAME/lovedones"
    echo ""
    echo "📋 Next steps:"
    echo "1. Go to your repository on GitHub"
    echo "2. Add repository topics (hackathon, alzheimers, healthcare, etc.)"
    echo "3. Upload a demo video"
    echo "4. Share your repository on social media"
    echo ""
    echo "🏆 Good luck with your hackathon submission!"
else
    echo "❌ Failed to push to GitHub. Please check your credentials and try again."
    exit 1
fi
