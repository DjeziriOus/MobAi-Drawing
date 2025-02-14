const mongoose = require("mongoose");

const itemSchema = new mongoose.Schema({
    id: { type: String, required: true, unique: true }, // ID unique
    level: { type: Number, default: 0 } ,// Valeur par défaut = 0
    available: { type: Boolean, default: false } // Valeur par défaut = 0
    
});

const Item = mongoose.model("Item", itemSchema);

module.exports = Item;
