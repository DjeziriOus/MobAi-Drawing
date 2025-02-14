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
                    ws.send(JSON.stringify({ type: "start game",payload: { owner: room.owner, players: room.players }  }));
                    return;
                }
                ws.send(JSON.stringify({ type: "party_joined", payload: { owner: room.owner, players: room.players } }));
            }
            else if(type== "play_turn")
                {
                    try {
                        const { id, prompt } = data; // Récupérer l'ID du joueur et le prompt
                
                        // Trouver la salle contenant le joueur ou le propriétaire
                        const room = await Room.findOne({
                            $or: [
                                { "owner.id": id },
                                { "players.id": id }
                            ]
                        });
                
                        if (!room) {
                            clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "Salle introuvable" } }));
                            return;
                        }
                
                        // Récupérer tous les joueurs (y compris l'owner)
                        let players = [room.owner, ...room.players];
                
                        // Trouver le joueur actuel
                        const currentPlayer = players.find(player => player.id === id);
                        if (!currentPlayer) {
                            clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "Joueur non trouvé dans la salle" } }));
                            return;
                        }
                
                        // Vérifier si c'est son tour
                        if (!currentPlayer.turn) {
                            clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "Ce n'est pas votre tour" } }));
                            return;
                        }
                
                        // Mettre à jour le prompt de la partie
                        room.prompt = prompt;
                        await room.save();
                
                        // Notifier tous les autres joueurs que le jeu a commencé
                        players.forEach(player => {
                            if (player.id !== id && clients.has(player.id)) {
                                clients.get(player.id)?.send(JSON.stringify({
                                    type: "launched_game",
                                    data: { prompt }
                                }));
                            }
                        });
                
                    } catch (error) {
                        console.error("Erreur lors du lancement du tour :", error);
                        clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "Erreur serveur" } }));
                    }
                }
        else if(type=="update_image")
         {
              try {
            const { id, image } = data; // Récupérer l'ID du joueur et l'image
    
            // Trouver la salle contenant le joueur ou le propriétaire
            const room = await Room.findOne({
                $or: [
                    { "owner.id": id },
                    { "players.id": id }
                ]
            });
    
            if (!room) {
                clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "Salle introuvable" } }));
                return;
            }
    
            // Récupérer tous les joueurs (y compris l'owner)
            let players = [room.owner, ...room.players];
    
            // Trouver le joueur actuel
            const currentPlayer = players.find(player => player.id === id);
            if (!currentPlayer) {
                clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "Joueur non trouvé dans la salle" } }));
                return;
            }
    
            // Vérifier si c'est son tour
            if (!currentPlayer.turn) {
                clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "Ce n'est pas votre tour" } }));
                return;
            }
    
            // Envoyer l'image mise à jour à tous les autres joueurs
            players.forEach(player => {
                if (player.id !== id && clients.has(player.id)) {
                    clients.get(player.id)?.send(JSON.stringify({
                        type: "updated_image",
                        data: { image }
                    }));
                }
            });
    
          } catch (error) {
             console.error("Erreur lors de la mise à jour de l'image :", error);
             clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "Erreur serveur" } }));
          }
        
        }
        else if(type="guess")
         {
                
           try {
            const { id, prompt } = data; // Récupérer l'ID du joueur et le mot deviné
    
            // Trouver la salle contenant le joueur ou le propriétaire
            const room = await Room.findOne({
                $or: [
                    { "owner.id": id },
                    { "players.id": id }
                ]
            });
    
            if (!room) {
                clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "Salle introuvable" } }));
                return;
            }
    
            // Récupérer tous les joueurs (y compris l'owner)
            let players = [room.owner, ...room.players];
    
            // Trouver l'index du joueur actuel
            const currentPlayerIndex = players.findIndex(player => player.id === id);
            if (currentPlayerIndex === -1) {
                clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "Joueur non trouvé dans la salle" } }));
                return;
            }
    
            // Vérifier si ce n'est PAS son tour (car il doit deviner, pas jouer)
            if (players[currentPlayerIndex].turn) {
                clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "C'est votre tour, vous ne pouvez pas deviner" } }));
                return;
            }
    
            // Vérifier si la réponse est correcte
            if (room.prompt === prompt) {
                // Incrémenter le score du joueur gagnant
                players[currentPlayerIndex].score += 1;
    
                // Notifier tout le monde que le joueur a trouvé la bonne réponse
                players.forEach(player => {
                    if (clients.has(player.id)) {
                        clients.get(player.id)?.send(JSON.stringify({
                            type: "player_won",
                            data: { id, message: `Le joueur ${id} a trouvé la bonne réponse !` }
                        }));
                    }
                });
    
                // Passer le tour au joueur suivant
                const currentTurnIndex = players.findIndex(player => player.turn);
                players[currentTurnIndex].turn = false;
    
                const nextTurnIndex = (currentTurnIndex + 1) % players.length;
                players[nextTurnIndex].turn = true;
    
                // Notifier le joueur suivant que c'est son tour
                if (clients.has(players[nextTurnIndex].id)) {
                    clients.get(players[nextTurnIndex].id)?.send(JSON.stringify({
                        type: "your_turn",
                        data: { message: "C'est votre tour !" }
                    }));
                }
    
                // Vérifier si on est au dernier tour (retour au premier joueur)
                if (nextTurnIndex === 0) {
                    const winner = players.reduce((best, player) => (player.score > best.score ? player : best), players[0]);
    
                    // Envoyer les scores finaux à chaque joueur
                    players.forEach(player => {
                        if (clients.has(player.id)) {
                            clients.get(player.id)?.send(JSON.stringify({
                                type: "game_over",
                                data: {
                                    message: "Fin du jeu",
                                    scores: players.map(p => ({ id: p.id, score: p.score })),
                                    winner: { id: winner.id, score: winner.score }
                                }
                            }));
                        }
                    });
                }
    
                // Sauvegarder les modifications
                await room.save();
            } else {
                // Mauvaise réponse
                clients.get(ws.id)?.send(JSON.stringify({ type: "wrong_guess", data: { message: "Mauvaise réponse, réessayez !" } }));
            }
    
            } catch (error) {
               console.error("Erreur lors du traitement du guess :", error);
               clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "Erreur serveur" } }));
            }
          }
    
        else if (type="timeout")
        {
                
           try {
            const id = data.id; // ID du joueur qui a dépassé le temps
    
            // Trouver la salle où ce joueur est owner ou player
            const room = await Room.findOne({
                $or: [
                    { "owner.id": id },
                    { "players.id": id }
                ]
            });
    
            if (!room) {
                ws.send(JSON.stringify({ type: "error", message: "Salle introuvable" }));
                return;
            }
    
            // Récupérer tous les joueurs (y compris l'owner)
            let players = [room.owner, ...room.players];
    
            // Trouver l'index du joueur actuel
            let currentPlayerIndex = players.findIndex(player => player.id === id);
    
            if (currentPlayerIndex === -1) {
                ws.send(JSON.stringify({ type: "error", message: "Joueur non trouvé dans la salle" }));
                return;
            }
    
            // Vérifier si c'est bien SON tour
            if (!players[currentPlayerIndex].turn) {
                ws.send(JSON.stringify({ type: "error", message: "Ce n'est pas votre tour" }));
                return;
            }
    
            // Passer le tour au joueur suivant
            players[currentPlayerIndex].turn = false; // Retirer le tour du joueur actuel
            let nextPlayerIndex = (currentPlayerIndex + 1) % players.length; // Déterminer le joueur suivant
            players[nextPlayerIndex].turn = true; // Donner le tour au suivant
    
            // Informer le joueur suivant
            const nextPlayer = clients.get(players[nextPlayerIndex].id);
            if (nextPlayer) {
                nextPlayer.send(JSON.stringify({ type: "your_turn", message: "C'est votre tour !" }));
            }
    
            // Mettre à jour le score du joueur qui a dépassé le temps
            players[currentPlayerIndex].score += 1;
    
            // Sauvegarder les modifications
            await room.save();
    
            // Informer tous les autres joueurs
            players.forEach(player => {
                if (player.id !== id) {
                    const playerWs = clients.get(player.id);
                    if (playerWs) {
                        playerWs.send(JSON.stringify({ 
                            type: "time_finished", 
                            message: `Le joueur ${id} a perdu son tour.` 
                        }));
                    }
                }
            });
    
            } catch (error) {
               console.error("Erreur lors du changement de tour :", error);
               ws.send(JSON.stringify({ type: "error", message: "Erreur serveur" }));
            }
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
