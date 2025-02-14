const mongoose = require("mongoose");

const playerSchema = new mongoose.Schema({
    id: { type: String, required: true },
    score: { type: Number, default: 0 },
    turn: { type: Boolean, default: false }
});
const roomSchema = new mongoose.Schema({
    owner: { type: playerSchema, required: true }, // Champ unique
    players: { type: [playerSchema], default: [] }, // Liste des joueurs (max 3 en plus de l'owner) // Champ unique
    code:{type:Number,unique:true},
    prompt:{type:String}
});

// Utiliser `promptSchema` au lieu de `itemSchema`
const Room = mongoose.model("Room", roomSchema);

module.exports = Room;
