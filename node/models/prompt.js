const mongoose = require("mongoose");

const promptSchema = new mongoose.Schema({
    prompt: { type: String, required: true, unique: true }, // Champ unique
    action: { type: String, default: "Easy" } // Valeur par défaut = 0
});

// Utiliser `promptSchema` au lieu de `itemSchema`
const Prompt = mongoose.model("Prompt", promptSchema);

module.exports = Prompt;
