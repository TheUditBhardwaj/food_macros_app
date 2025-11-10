# app.py (updated to use nutrition_data.json)
from fastapi import FastAPI, File, UploadFile, HTTPException
import uvicorn
import tensorflow as tf
import numpy as np
from PIL import Image
import io
import json
import os

app = FastAPI(title="Food Macro Detector")

MODEL_PATH = "food_classifier_model1.h5"
CLASSES_FILE = "food_macros_app/food_macros_backend/class_names.txt"
NUTRITION_JSON = "food_macros_app/food_macros_backend/nutrition_database.json"   # <-- your JSON file here
IMG_SIZE = (224, 224)

# ---------------------------
# Helper: normalize food keys
# ---------------------------
def normalize_key(s: str) -> str:
    if s is None:
        return ""
    s = s.strip().lower()
    s = s.replace("_", " ").replace("-", " ")
    s = " ".join(s.split())  # collapse multiple spaces
    return s

# ---------------------------
# Load model & classes once
# ---------------------------
model = tf.keras.models.load_model(MODEL_PATH)
with open(CLASSES_FILE, "r") as f:
    class_names = [line.strip() for line in f.readlines()]

# ---------------------------
# Load nutrition JSON robustly
# ---------------------------
if not os.path.exists(NUTRITION_JSON):
    raise FileNotFoundError(f"{NUTRITION_JSON} not found. Put your nutrition JSON in the project folder.")

with open(NUTRITION_JSON, "r", encoding="utf-8") as f:
    raw = json.load(f)

# Build a normalized mapping: normalized_name -> nutrition_record
nutrition_map = {}

# Case 1: raw is a list of records with a "Food" or "food" field
if isinstance(raw, list):
    for rec in raw:
        # tolerate different field names
        key = rec.get("Food") or rec.get("food") or rec.get("name") or None
        if key:
            nutrition_map[normalize_key(key)] = rec
        else:
            # if no explicit name field, try to find a key by heuristics (skip if not possible)
            continue

# Case 2: raw is a dict keyed by food name
elif isinstance(raw, dict):
    # The values might be nested dicts with nutrition fields
    for k, v in raw.items():
        nutrition_map[normalize_key(k)] = v

else:
    raise ValueError("Unsupported JSON structure for nutrition data. Use a list-of-records or dict-of-records.")

# ---------------------------
# Preprocess & lookup helpers
# ---------------------------
def preprocess_image_bytes(image_bytes):
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB").resize(IMG_SIZE)
    arr = np.array(img).astype("float32")
    arr = tf.keras.applications.efficientnet.preprocess_input(arr)
    arr = np.expand_dims(arr, axis=0)
    return arr

def lookup_nutrition(food_label: str):
    """
    Try multiple lookup strategies:
    1) exact normalized match,
    2) replace underscores with spaces,
    3) try first token (e.g., 'chicken_curry' -> 'chicken'),
    4) try fuzzy fallback: iterate nutrition_map keys looking for substring match (last resort).
    """
    if not food_label:
        return None

    norm = normalize_key(food_label)                 # e.g., "chicken curry"
    # 1) exact normalized lookup
    if norm in nutrition_map:
        return format_nutrition(nutrition_map[norm], food_label)

    # 2) try splitting underscores / tokens (common with Food-101)
    tokens = norm.split()
    if len(tokens) > 1:
        # try last token (dish main word) and first token heuristics
        for t in ( " ".join(tokens), tokens[0], tokens[-1]):
            if t in nutrition_map:
                return format_nutrition(nutrition_map[t], food_label)

    # 3) fallback substring search (less reliable)
    for k, rec in nutrition_map.items():
        if k in norm or norm in k:
            return format_nutrition(rec, food_label)

    # not found
    return None

def format_nutrition(rec, queried_label):
    """
    Normalize the returned nutrition fields into a consistent dict.
    Accepts records of different shapes.
    """
    # If rec contains a top-level 'Food' name, preserve it as display name
    display_name = rec.get("Food") or rec.get("food") or rec.get("name") or queried_label
    def get_num(fields):
        for fld in fields:
            if fld in rec:
                try:
                    return float(rec[fld])
                except Exception:
                    try:
                        return float(str(rec[fld]).replace(",", ""))
                    except Exception:
                        return None
        return None

    calories = get_num(["Calories_kcal", "calories", "Calories", "calorie_kcal"])
    protein  = get_num(["Protein_g", "protein_g", "protein"])
    carbs    = get_num(["Carbs_g", "carbs_g", "carbs", "carbohydrates"])
    fat      = get_num(["Fat_g", "fat_g", "fat"])

    return {
        "Food": display_name,
        "Calories_kcal": calories,
        "Protein_g": protein,
        "Carbs_g": carbs,
        "Fat_g": fat
    }

# ---------------------------
# FastAPI endpoint
# ---------------------------
@app.post("/predict")
async def predict(file: UploadFile = File(...), topk: int = 3):
    if file.content_type.split("/")[0] != "image":
        raise HTTPException(status_code=400, detail="File must be an image")
    contents = await file.read()
    x = preprocess_image_bytes(contents)
    preds = model.predict(x)[0]
    top_indices = preds.argsort()[-topk:][::-1]
    top = [{"class": class_names[i], "prob": float(preds[i])} for i in top_indices]
    top1_label = top[0]["class"]
    nutrition = lookup_nutrition(top1_label)
    response = {
        "predictions": top,
        "top1_nutrition": nutrition,
        "note": "Nutrition lookup uses your local JSON file and simple normalization heuristics. If nutrition is null, add a matching entry or provide a mapping file."
    }
    return response

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)