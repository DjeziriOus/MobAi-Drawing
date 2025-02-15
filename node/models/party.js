const mongoose = require("mongoose");

const partySchema = new mongoose.Schema({
    id1: { type: String, required: true, unique: true }, // ID unique
    id2: { type: String, required: true, unique: true }, // ID unique
    state:{ type: String, default:"open" }, 
    prompt:{ type: String } 
    
});

// Utiliser `promptSchema` au lieu de `itemSchema`
const Party = mongoose.model("Party", partySchema);

module.exports = Party;
