from typing import Dict
from fastapi import FastAPI, File, HTTPException, UploadFile
import cv2
import numpy as np
from tensorflow import keras

app = FastAPI()

# Load the model
try:
    model = keras.models.load_model("keras.h5")
    print("Model loaded successfully.")
except Exception as e:
    print(f"Error loading model: {e}")
    raise RuntimeError("Failed to load model.")

def preprocess_image(image: np.ndarray, image_size: int = 28) -> np.ndarray:
    """
    Preprocess the input image to match the model's requirements.

    Args:
        image (np.ndarray): The input image in grayscale.
        image_size (int): The target size for resizing the image.

    Returns:
        np.ndarray: The preprocessed image ready for prediction.
    """
    try:
        # Resize the image to match the model's input size
        img_resized = cv2.resize(image, (image_size, image_size))

        # Normalize pixel values to the range [0, 1]
        img_normalized = img_resized / 255.0

        # Reshape to match the model's expected input shape (1, image_size, image_size, 1)
        img_reshaped = img_normalized.reshape(1, image_size, image_size, 1)

        return img_reshaped
    except Exception as e:
        raise ValueError(f"Error in preprocessing image: {e}")

@app.post("/predict")
async def predict_sketch(file: UploadFile = File(...)) -> Dict:
    """
    Predict the class of a sketch image.

    Args:
        file (UploadFile): The uploaded image file.

    Returns:
        Dict: A dictionary containing the prediction results.
    """
    try:
        # Read the file content
        contents = await file.read()

        # Convert the file content to a NumPy array
        nparr = np.frombuffer(contents, np.uint8)

        # Decode the image
        image = cv2.imdecode(nparr, cv2.IMREAD_GRAYSCALE)
        if image is None:
            raise HTTPException(status_code=400, detail="Invalid image file")

        # Process the image
        processed_sketch = preprocess_image(image)

        # Make prediction
        predictions = model.predict(processed_sketch)

        # Get prediction results
        predicted_class_index = int(np.argmax(predictions))
        confidence = float(predictions[0][predicted_class_index])

        # Prepare response
        response = {
            "filename": file.filename,
            "predicted_class": predicted_class_index,
            "confidence": confidence,
            "class_index": predicted_class_index
        }

        return response
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {e}")
