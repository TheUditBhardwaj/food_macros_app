# predict.py
import tensorflow as tf
import numpy as np
from PIL import Image
import sys

MODEL_PATH = "food_macros_app/food_macros_backend/food_classifier_model1.h5"
CLASSES_FILE = "food_macros_app/food_macros_backend/class_names.txt"
IMG_SIZE = (224, 224)

# Load model
model = tf.keras.models.load_model(MODEL_PATH)

# Load class names
with open(CLASSES_FILE, "r") as f:
    class_names = [line.strip() for line in f.readlines()]

def preprocess_image(image_path):
    img = Image.open(image_path).convert("RGB").resize(IMG_SIZE)
    arr = np.array(img).astype("float32")
    arr = tf.keras.applications.efficientnet.preprocess_input(arr)
    arr = np.expand_dims(arr, axis=0)
    return arr

def predict(image_path, topk=3):
    x = preprocess_image(image_path)
    preds = model.predict(x)[0]
    top_indices = preds.argsort()[-topk:][::-1]
    results = []
    for i in top_indices:
        results.append({"class": class_names[i], "prob": float(preds[i])})
    return results

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python predict.py 998474.jpg")
        sys.exit(1)
    res = predict(sys.argv[1], topk=3)
    print(res)