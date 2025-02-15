from flask import Flask, request, jsonify
import torch
import torch.nn as nn

app = Flask(__name__)

# 📌 Définition du modèle DQN (doit être le même que dans l'entraînement)
class DQN(nn.Module):
    def __init__(self, input_dim, output_dim):
        super(DQN, self).__init__()
        self.fc1 = nn.Linear(input_dim, 128)
        self.fc2 = nn.Linear(128, 128)
        self.fc3 = nn.Linear(128, output_dim)

    def forward(self, x):
        x = torch.relu(self.fc1(x))
        x = torch.relu(self.fc2(x))
        return self.fc3(x)

# 📌 Chargement du modèle entraîné
state_dim = 3  # Entrée : (time, accuracy, level)
action_dim = 3  # Sortie : (facile, même, difficile)
policy_net = DQN(state_dim, action_dim)
policy_net.load_state_dict(torch.load("dqn_model.pth"))
policy_net.eval()  # Mode évaluation

# 📌 Fonction pour faire une prédiction
def predire(time, accuracy, level):
    state = torch.tensor([time, accuracy, level], dtype=torch.float32)

    with torch.no_grad():
        q_values = policy_net(state)
        new_action = torch.argmax(q_values).item()

    # Mise à jour du niveau en fonction de l'action prédite
    if new_action == 0:  # Plus facile
        new_level = max(level - 1, 0)
    elif new_action == 2:  # Plus difficile
        new_level = min(level + 1, 2)
    else:  # Même difficulté
        new_level = level

    return new_action, new_level

# 📌 Route API pour prédire la prochaine action
@app.route("/predict", methods=["POST"])
def predict():
    data = request.json
    time = data.get("time")
    accuracy = data.get("accuracy")
    level = data.get("level")

    if time is None or accuracy is None or level is None:
        return jsonify({"error": "Données manquantes"}), 400

    new_action, new_level = predire(time, accuracy, level)
    
    return jsonify({"new_action": new_action, "new_level": new_level})

# 📌 Lancer le serveur Flask
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
