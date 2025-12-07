🌾 Smart Agriculture for Hilly Regions

This project is developed with a focus on the Smart India Hackathon (SIH) 2025
Problem Statement ID: 25062 – Implementation of Smart Agriculture for Efficient Cultivation in Hilly Regions

The system leverages IoT, machine learning, and smart analytics to support farmers in hilly terrains and improve productivity through real-time monitoring and intelligent decision-making.

🚀 Key Highlights

Flutter Mobile Application for cross-platform usability

Machine Learning Model deployed via Google Colab

Remote API Exposure using Ngrok enabling real-time ML predictions from the app

Designed for precision farming in hilly regions

🛠 Technology Stack
Component	Technology
Frontend	Flutter (Dart)
Backend / API	Python (Colab Notebook)
ML Deployment	Ngrok Tunnel
Tools	Google Colab, Sensors (optional), Firebase/Database (if applicable)
🔗 ML Model Integration Workflow

ML model runs in Google Colab

Model endpoint exposed through Ngrok HTTP tunnel

Flutter app interacts with the Ngrok URL to get predictions in real-time

▶️ How to Run the Project
Run Flutter App
flutter run

Start the ML Model Server

Open the Colab notebook

Start the API service (FastAPI / Flask / etc.)

Run Ngrok:

!ngrok http 8000


Copy the public URL

Add it to Flutter app’s API endpoint config

✨ Features

Soil & climate parameter analysis (based on inputs or sensors)

Smart irrigation recommendation

Suitable crop prediction for hilly terrain

Real-time insights and monitoring dashboard

Improves efficiency and sustainability in agriculture practices
