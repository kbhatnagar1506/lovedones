#!/bin/bash

# Deploy LovedOnes Servers to Heroku
echo "🚀 Deploying LovedOnes Servers to Heroku"
echo "========================================"

# Set environment variables
export VAPI_API_KEY="19de0c70-e127-4e3d-b65b-833376a4de0c"
export OPENAI_API_KEY="YOUR_OPENAI_API_KEY_HERE"

# Deploy Emergency Calling Server
echo "📞 Deploying Emergency Calling Server..."
cd calling_server

# Initialize git if not already done
if [ ! -d ".git" ]; then
    git init
    git add .
    git commit -m "Initial commit - Emergency Calling Server"
fi

# Create Heroku app for emergency calling
heroku create lovedones-emergency-calling --region us

# Set environment variables
heroku config:set VAPI_API_KEY=$VAPI_API_KEY -a lovedones-emergency-calling

# Deploy
git add .
git commit -m "Deploy emergency calling server"
git push heroku main

echo "✅ Emergency Calling Server deployed!"
echo "🌐 URL: https://lovedones-emergency-calling.herokuapp.com"

cd ..

# Deploy Voice Reminder Server
echo "🎤 Deploying Voice Reminder Server..."
cd voice_reminder_server

# Initialize git if not already done
if [ ! -d ".git" ]; then
    git init
    git add .
    git commit -m "Initial commit - Voice Reminder Server"
fi

# Create Heroku app for voice reminders
heroku create lovedones-voice-reminders --region us

# Set environment variables
heroku config:set VAPI_API_KEY=$VAPI_API_KEY -a lovedones-voice-reminders
heroku config:set OPENAI_API_KEY=$OPENAI_API_KEY -a lovedones-voice-reminders

# Deploy
git add .
git commit -m "Deploy voice reminder server"
git push heroku main

echo "✅ Voice Reminder Server deployed!"
echo "🌐 URL: https://lovedones-voice-reminders.herokuapp.com"

cd ..

echo ""
echo "🎉 Both servers deployed successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Update iOS app with deployed server URLs"
echo "2. Create VAPI agent with the provided configuration"
echo "3. Test the integration"
echo ""
echo "🔧 Server URLs:"
echo "Emergency Calling: https://lovedones-emergency-calling.herokuapp.com"
echo "Voice Reminders: https://lovedones-voice-reminders.herokuapp.com"

