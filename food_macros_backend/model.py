import numpy as np
from PIL import Image
import io
import json
import tensorflow as tf


import os
model_path = os.path.join(os.path.dirname(__file__), "food_classifier_model.h5")
model = tf.keras.models.load_model(model_path)

# Load class labels
def load_class_labels():
    label_path = os.path.join(os.path.dirname(__file__), "class_names.txt")
    with open(label_path, "r") as f:
        return [line.strip() for line in f.readlines()]

class_labels = load_class_labels()

# Load nutrition database
nutrition_db_path = os.path.join(os.path.dirname(__file__), "nutrition_database.json")
with open(nutrition_db_path, "r") as f:
    nutrition_db = json.load(f)

# Image preprocessing function
def preprocess_image(image_bytes: bytes):
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = image.resize((224, 224))
    img_array = np.array(image) / 255.0
    return np.expand_dims(img_array, axis=0)

# Predict macros using model and nutrition database
def predict_macros(preprocessed_image_data):
    if preprocessed_image_data is not None:
        prediction = model.predict(preprocessed_image_data)
        predicted_class_index = np.argmax(prediction)
        predicted_label = class_labels[predicted_class_index]
        lookup_key = predicted_label.lower().replace(" ", "_")  # Ensure JSON key format matches

        nutrition_info = nutrition_db.get(lookup_key)

        if nutrition_info:
            return {
                "food_item": predicted_label,
                "serving_size": nutrition_info.get("serving_size", "Unknown"),
                "calories_kcal": nutrition_info.get("calories", 0.0),
                "protein_g": nutrition_info.get("protein", 0.0),
                "fat_g": nutrition_info.get("fat", 0.0),
                "carbs_g": nutrition_info.get("carbs", 0.0),
                "fiber_g": nutrition_info.get("fiber", 0.0),
                "sugar_g": nutrition_info.get("sugar", 0.0),
            }

        # Fallback if item not in database
        return {
            "food_item": predicted_label,
            "serving_size": "Unknown",
            "calories_kcal": 0.0,
            "protein_g": 0.0,
            "fat_g": 0.0,
            "carbs_g": 0.0,
            "fiber_g": 0.0,
            "sugar_g": 0.0
        }

    return {
        "food_item": "Unknown",
        "serving_size": "Unknown",
        "calories_kcal": 0.0,
        "protein_g": 0.0,
        "fat_g": 0.0,
        "carbs_g": 0.0,
        "fiber_g": 0.0,
        "sugar_g": 0.0
    }

# Example usage
# if __name__ == "__main__":
#     with open("food_macros_backend/image.png", "rb") as f:
#         image_bytes = f.read()

#     preprocessed = preprocess_image(image_bytes)
#     result = predict_macros(preprocessed)
#     print(result)