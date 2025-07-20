from fastapi import FastAPI, File, UploadFile, HTTPException
from pydantic import BaseModel
from typing import Dict
import uvicorn
import io
import base64
# Import actual model functions
from model import preprocess_image, predict_macros

app = FastAPI(
    title="Food Macros Finder API",
    description="An API to predict food macros from an image.",
    version="1.0.0"
)

# Define a Pydantic model for the response structure
class MacroPrediction(BaseModel):
    food_item: str
    serving_size: str
    protein_g: float
    fat_g: float
    carbs_g: float
    fiber_g: float
    sugar_g: float
    calories_kcal: float

@app.get("/")
async def root():
    return {"message": "Welcome to the Food Macros Finder API!"}

@app.post("/predict_macros/", response_model=MacroPrediction)
async def upload_image_for_prediction(file: UploadFile = File(...)):
    """
    Receives an image file, preprocesses it, predicts food item, and returns nutrition data from the database.
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Invalid file type. Please upload an image.")

    try:
        # Read the image bytes
        image_bytes = await file.read()

        # Preprocess the image for the model
        preprocessed_data = preprocess_image(image_bytes)

        # Get predictions from the model
        # In a real scenario, this would be model.predict(preprocessed_data)
        macros = predict_macros(preprocessed_data)

        return MacroPrediction(**macros)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {e}")

# To run the app (add this block if you want to run directly via python main.py)
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)