from flask import Flask,request, jsonify
from flask_cors import CORS

app = Flask(__name__)
application=app
CORS(app)

@app.route('/',methods=['POST'])
def get_level_action():
    try:
        data = request.get_json()  # Récupérer le JSON envoyé
        if not data:
            return jsonify({"error": "No JSON data received"}), 400
        
        # Traitement des données (exemple : affichage)
        print("JSON reçu :", data)
        # Récupérer un attribut spécifique, par exemple "name"
        time= data.get("time", "Valeur par défaut")
        accuracy= data.get("accuracy", "Valeur par défaut")  
        action= data.get("action", "Valeur par défaut")  

        return jsonify({"level":"","action":"Medium"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

   


@app.route('/about')
def route():
    return "hello world ça marche"
if __name__ == '__main__':
    app.run(debug=True, port=5000)