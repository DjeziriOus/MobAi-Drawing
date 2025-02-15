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
    Preprocess the input image to match the model's requirements, including handling transparency.

    Args:
        image (np.ndarray): The input image in RGBA format (for transparent PNGs).
        image_size (int): The target size for resizing the image.

    Returns:
        np.ndarray: The preprocessed image ready for prediction.
    """
    try:
        # Check if the image has an alpha channel (transparency)
        if image.shape[-1] == 4:
            # Separate the alpha channel
            _, _, _, alpha = cv2.split(image)

            # Create a black background where transparency exists
            background = np.zeros_like(alpha)

            # Merge the font with the black background
            image = cv2.merge((alpha, alpha, alpha))  # Convert transparency into grayscale

        # Convert to grayscale if not already
        if len(image.shape) == 3:  # If still in RGB format
            image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Invert the image to match white font on black background
        img_inverted = cv2.bitwise_not(image)

        # Resize the image to match the model's input size
        img_resized = cv2.resize(img_inverted, (image_size, image_size))

        # Normalize pixel values to the range [0, 1]
        img_normalized = img_resized / 255.0

        # Reshape to match the model's expected input shape (1, image_size, image_size, 1)
        img_reshaped = img_normalized.reshape(1, image_size, image_size, 1)

        return img_reshaped
    except Exception as e:
        raise ValueError(f"Error in preprocessing image: {e}")

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

    classes = [
    "drums", "sun", "laptop", "anvil", "baseball_bat", "ladder", "eyeglasses", 
    "grapes", "book", "dumbbell", "traffic_light", "wristwatch", "wheel", 
    "shovel", "bread", "table", "tennis_racquet", "cloud", "chair", "headphones", 
    "face", "eye", "airplane", "snake", "lollipop", "power_outlet", "pants", 
    "mushroom", "star", "sword", "clock", "hot_dog", "syringe", "stop_sign", 
    "mountain", "smiley_face", "apple", "bed", "shorts", "broom", "diving_board", 
    "flower", "spider", "cell_phone", "car", "camera", "tree", "square", "moon", 
    "radio", "hat", "pizza", "axe", "door", "tent", "umbrella", "line", "cup", 
    "fan", "triangle", "basketball", "pillow", "scissors", "t-shirt", "tooth", 
    "alarm_clock", "paper_clip", "spoon", "microphone", "candle", "pencil", 
    "envelope", "saw", "frying_pan", "screwdriver", "helmet", "bridge", 
    "light_bulb", "ceiling_fan", "key", "donut", "bird", "circle", "beard", 
    "coffee_cup", "butterfly", "bench", "rifle", "cat", "sock", "ice_cream", 
    "moustache", "suitcase", "hammer", "rainbow", "knife", "cookie", "baseball", 
    "lightning", "bicycle"
]

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
        predicted_class = classes[predicted_class_index]

        # Prepare response
        response = {
            "filename": file.filename,
            "predicted_class": predicted_class,
            "confidence": confidence,
            "class_index": predicted_class_index
        }
        
        print(response)
        return response
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {e}")
