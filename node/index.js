const express = require("express");
const { createServer } = require("http");
const { WebSocketServer } = require("ws");
const mongoose = require("mongoose");
const cors = require("cors");

const Item = require("./models/Item");
const Prompt = require("./models/prompt");
const Party = require("./models/party");
const Room = require("./models/room");

const app = express();


// MongoDB Connection
mongoose.connect("mongodb://admin:secret@localhost:27017/mydb?authSource=admin", {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
    .then(() => {
        console.log("✅ Connected to MongoDB");
        insertPrompts();
    })
    .catch(err => console.error("❌ MongoDB connection error:", err));

// Create HTTP Server and WebSocket Server
const server = createServer(app);
const wss = new WebSocketServer({ server });

// Insert default prompts
const promptsData = [
    { prompt: "Helicopter", action: "Medium" },
    { prompt: "Computer", action: "Hard" },
    { prompt: "Cat", action: "Easy" },
    { prompt: "Mountain", action: "Medium" },
    { prompt: "Robot", action: "Hard" },
    // ... (other prompts)
];
async function insertPrompts() {
    try {
        for (const promptData of promptsData) {
            await Prompt.updateOne(
                { prompt: promptData.prompt }, 
                { $set: promptData }, 
                { upsert: true }
            );
        }
        console.log("✅ Prompts inserted/updated successfully!");
    } catch (error) {
        console.error("❌ Error inserting prompts:", error.message);
    }
}

// WebSocket Connections
wss.on("connection", (ws) => {
    console.log("A user connected.");
    
    const testMessage = JSON.stringify({ type: "test", message: "Hello, client!" });
    ws.send(testMessage);
    console.log("Sent message to client:", testMessage);


    ws.on("message", async (message) => {
        try {
            const data = JSON.parse(message);
            console.log("Received message:", data);

            if (data.type === "send_data") {
                const { time, accuracy, action } = data.payload;
                const id = ws.id || Date.now(); // Assign a unique ID if none exists
                let item = await Item.findOne({ id });
                
                if (!item) {
                    item = new Item({ id, level: 0 });
                    await item.save();
                }
                
                let level = item.level;
                const prompts = await Prompt.find({ action: "Medium" }).select("prompt -_id");
                const randomIndex = Math.floor(Math.random() * prompts.length);
                const responseData = { level, prompt: prompts[randomIndex] };

                ws.send(JSON.stringify({ type: "message", payload: responseData }));
            }

            // Additional WebSocket events
            else if (data.type === "create_room") {
                console.log(data)
                
                const randomCode = Math.floor(100000 + Math.random() * 900000).toString();
                const room = await Room.create({ owner: { id: data.id, score: 0, turn: true }, code: randomCode });
                ws.send(JSON.stringify({ type: "party_created", payload: { code: randomCode } }));
            }

            else if (data.type === "join_room") {
                const code = data.payload;

                const room = await Room.findOne({ code });
                console.log(room)
                if (!room) {
                    ws.send(JSON.stringify({ type: "error", payload: { message: "Room not found" } }));
                    return;
                }

                console.log(room)
                if (room.players.length == 3) {
                    ws.send(JSON.stringify({ type: "start", payload: { message: "Room is full" } }));
                    
                }

                if (room.players.length > 3) {
                    ws.send(JSON.stringify({ type: "error", payload: { message: "Room is full" } }));
                    return;
                }

                room.players.push({ id: data.id, score: 0, turn: false });
                await room.save();
                if (room.players.length == 4) {
                    ws.send(JSON.stringify({ type: "start game" ,payload: { owner: room.owner, players: room.players }}));
                }
                ws.send(JSON.stringify({ type: "party_joined", payload: { owner: room.owner, players: room.players } }));
            }
        } catch (error) {
            console.error("Error handling message:", error);
            ws.send(JSON.stringify({ type: "error", payload: { message: "Server error" } }));
        }
    });

    ws.on("close", () => {
        console.log("A user disconnected.");
    });
});

// Start the server
const PORT = 8000;
server.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});