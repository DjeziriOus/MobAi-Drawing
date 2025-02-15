const express = require("express");
const { createServer } = require("http");
const { WebSocketServer } = require("ws");
const mongoose = require("mongoose");
const cors = require("cors");
const { v4: uuidv4 } = require("uuid");
const fs = require('fs');

const sharp = require("sharp");
const Item = require("./models/Item");
const Prompt = require("./models/prompt");
const Party = require("./models/party");
const Room = require("./models/room");
const FormData = require('form-data');

const axios = require('axios');

const app = express();
const clients = new Map();

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
    { prompt: "airplane", action: 1 },
    { prompt: "alarm clock", action: 2 },
    { prompt: "ambulance", action: 1 },
    { prompt: "angel", action: 0 },
    { prompt: "animal migration", action: 1 },
    { prompt: "ant", action: 0 },
    { prompt: "apple", action: 0 },
    { prompt: "axe", action: 2 },
    { prompt: "backpack", action: 2 },
    { prompt: "banana", action: 0 },
    { prompt: "bandage", action: 2 },
    { prompt: "barn", action: 1 },
    { prompt: "baseball bat", action: 2 },
    { prompt: "basket", action: 2 },
    { prompt: "bear", action: 0 },
    { prompt: "bee", action: 0 },
    { prompt: "bicycle", action: 0 },
    { prompt: "binoculars", action: 2 },
    { prompt: "bird", action: 0 },
    { prompt: "book", action: 2 },
    { prompt: "boomerang", action: 2 },
    { prompt: "bottlecap", action: 2 },
    { prompt: "bowtie", action: 2 },
    { prompt: "brain", action: 2 },
    { prompt: "bread", action: 0 },
    { prompt: "bridge", action: 1 },
    { prompt: "bus", action: 1 },
    { prompt: "butterfly", action: 0 },
    { prompt: "cactus", action: 1 },
    { prompt: "calculator", action: 2 },
    { prompt: "calendar", action: 2 },
    { prompt: "camel", action: 0 },
    { prompt: "camera", action: 2 },
    { prompt: "candle", action: 2 },
    { prompt: "car", action: 1 },
    { prompt: "castle", action: 1 },
    { prompt: "cat", action: 0 },
    { prompt: "ceiling fan", action: 2 },
    { prompt: "cell phone", action: 2 },
    { prompt: "chair", action: 2 },
    { prompt: "church", action: 1 },
    { prompt: "circle", action: 2 },
    { prompt: "cloud", action: 1 },
    { prompt: "coffee cup", action: 2 },
    { prompt: "compass", action: 2 },
    { prompt: "computer", action: 2 },
    { prompt: "cookie", action: 0 },
    { prompt: "cruise ship", action: 1 },
    { prompt: "dog", action: 0 },
    { prompt: "dolphin", action: 0 },
    { prompt: "door", action: 2 },
    { prompt: "dragon", action: 0 },
    { prompt: "drill", action: 2 },
    { prompt: "drums", action: 2 },
    { prompt: "duck", action: 0 },
    { prompt: "elephant", action: 0 },
    { prompt: "eye", action: 2 },
    { prompt: "firetruck", action: 1 },
    { prompt: "fish", action: 0 },
    { prompt: "flower", action: 0 },
    { prompt: "giraffe", action: 0 },
    { prompt: "guitar", action: 2 },
    { prompt: "hammer", action: 2 },
    { prompt: "helicopter", action: 1 },
    { prompt: "hourglass", action: 2 },
    { prompt: "house", action: 1 },
    { prompt: "ice cream", action: 0 },
    { prompt: "key", action: 2 },
    { prompt: "ladder", action: 2 },
    { prompt: "lighthouse", action: 1 },
    { prompt: "lion", action: 0 },
    { prompt: "moon", action: 1 },
    { prompt: "motorbike", action: 1 },
    { prompt: "ocean", action: 1 },
    { prompt: "pencil", action: 2 },
    { prompt: "pig", action: 0 },
    { prompt: "plane", action: 1 },
    { prompt: "rainbow", action: 1 },
    { prompt: "scissors", action: 2 },
    { prompt: "shark", action: 0 },
    { prompt: "snowflake", action: 1 },
    { prompt: "star", action: 1 },
    { prompt: "submarine", action: 1 },
    { prompt: "sun", action: 1 },
    { prompt: "telescope", action: 2 },
    { prompt: "tent", action: 1 },
    { prompt: "toothbrush", action: 2 },
    { prompt: "tree", action: 1 },
    { prompt: "umbrella", action: 2 },
    { prompt: "violin", action: 2 },
    { prompt: "volcano", action: 1 },
    { prompt: "watch", action: 2 },
    { prompt: "watermelon", action: 0 },
    { prompt: "wheel", action: 2 },
    { prompt: "windmill", action: 1 },
    { prompt: "zebra", action: 0 },
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
    ws.id = uuidv4();
    

    const testMessage = JSON.stringify({ type: "test", message: "Hello, client!" });
    ws.send(testMessage);
    console.log("Sent message to client:", testMessage);


    ws.on("message", async (message) => {
        try {
            const data = JSON.parse(message);
            clients.set(data.id, ws);
  

            if (data.type === "start rl") {
                const {id} = data;
                
            
                let item = await Item.findOne({ id });
            
                if (!item) {
                    item = new Item({ id, level: 0 });
                    await item.save();
                }
            
                let level = item.level;
                let time = item.time;
                let accuracy = item.accuracy;
            
                try {
                    // Construire un objet JSON à envoyer
                    const payload = { time, accuracy ,level};
            
                    const response = await axios.post("http://127.0.0.1:5000/predict/", payload, {
                        headers: { "Content-Type": "application/json" },
                    });
            
                    console.log("Réponse de Flask:", response.data);
                    const prompts = await Prompt.find({ action: response.data.action }).select("prompt -_id");
                    if (prompts.length === 0) {
                        console.warn("Aucun prompt trouvé pour l'action 'Medium'.");
                        ws.send(JSON.stringify({ type: "prompt_start", payload: { level, prompt: null } }));
                        return;
                    }
                
                    const randomIndex = Math.floor(Math.random() * prompts.length);
                    const responseData = { level:response.data.level, prompt: prompts[randomIndex].prompt };
                    item.level = response.data.level;
                    item.save();
                
                    ws.send(JSON.stringify({ type: "prompt", payload: responseData }));
                } catch (error) {
                    console.error("Erreur lors de l'envoi à Flask:", error.message);
                }
            
                // Récupération des prompts et gestion du cas vide
               
            }
            
            else if(data.type=="find room")
            {
                let item = await Item.findOne({ id:data.id });

                const randomIndex = Math.floor(Math.random() * promptsData.length);
                const prompt= promptsData[randomIndex].prompt;

                if (!item) {
                    item = new Item({ id:data.id, level: 0 });
                    await item.save();
                }

                await Item.findOneAndUpdate(
                    { id:data.id },
                    { available: true }
                );

                let item2 = await Item.findOne({ level:item.level, id: { $ne: data.id },available:true });

                if (!item2) return;

                let party = await Party.create({ id1: item.id, id2: item2.id ,prompt});

                const response = JSON.stringify({ type: "1vs_response", party });
                item.available=false
                item2.available=false

                item.save()
                item2.save()


                ws.send(response);
                
                if (clients.has(item2.id)) {
                    clients.get(item2.id).send(response); // Envoie aussi au deuxième joueur
                 } // Envoie aussi au deuxième joueur
            }

            else if (data.type=="send pic")
            {
                const imageBuffer = Buffer.from(data.svg, 'utf-8');
                const id = data.id 
        
                sharp(imageBuffer)
        .ensureAlpha() // Ensure the image has an alpha channel (transparency)
        .extractChannel('alpha') // Extract the alpha channel (transparency mask)
        .toColourspace('b-w') // Convert transparency into a grayscale image
        .negate() // Invert the image (to make font white and background black)
        .resize(28, 28) 
                .toFile(`${id}.png`)
                .then(async() => {console.log("Conversion terminée !")
                    const formData = new FormData();
                    
                   
        formData.append('file',fs.createReadStream(`${id}.png`) );

        try {
            const response = await axios.post('http://127.0.0.1:8000/predict', formData, {
                headers: formData.getHeaders()
            });
            console.log('Réponse de FastAPI:', response.data);
            
            const predictedClass = response.data.predicted_class;
            const accuracy = response.data.confidence;
            
            ws.send(JSON.stringify({ type: "ai_guessed", guess: predictedClass.toString(), accuracy: accuracy.toString() }))
        } catch (error) {
            console.error('Erreur lors de l\'envoi à FastAPI:', error.message);
        }
                })
                .catch(err => console.error("Erreur :", err));

        // 📌 Envoi de l'image à FastAPI
        
            }
            else if (data.type=="success")
            {
                let item2 = await Item.findOne({ id:data.lid});
                let party = await Party.updateOne(
                    { 
                        $or: [
                            { $and: [ { id1: data.lid }, { id2: data.id }, { state: "open" } ] },
                            { $and: [ { id1: data.id }, { id2: data.lid }, { state: "open" } ] }
                        ]
                    },
                    { $set: { state: "finished" } }
                );
                if(!party) ws.send(JSON.stringify({ type: "error", payload: { message: "Party not available" } }));

                ws.send(JSON.stringify({ type: "you win", payload: { message: "Party finished" } }))
                clients.get(item2.id).send(JSON.stringify({ type: "loser", lid:data.lid }))
            }

            else if (data.type=="timeout_draw")
                {
                    let item2 = await Item.findOne({ id: { $ne: data.id } });
                    let party = await Party.updateOne(
                        { 
                            $or: [
                                { $and: [ { id1: item2.id }, { id2: data.id }, { state: "open" } ] },
                                { $and: [ { id1: data.id }, { id2: item2.id }, { state: "open" } ] }
                            ]
                        },
                        { $set: { state: "finished" } }
                    );
                    if(!party) ws.send(JSON.stringify({ type: "error", payload: { message: "Party not available" } }));
    
                    ws.send(JSON.stringify({ type: "draw", payload: { message: "Party finished" } }))
                    clients.get(item2.id).send(JSON.stringify({ type: "draw", payload: { message: "Party finished" } }))
                }

            // Additional WebSocket events
            else if (data.type == "create_room") {
                console.log(data)
                console.log('aaaaaaaaaaaaaaaaaa')
                
                const randomCode = Math.floor(100000 + Math.random() * 900000).toString();
                const room = await Room.create({ owner: { id: data.id, score: 0, turn: true }, code: randomCode ,prompt:data.prompt});
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
                

                if (room.players.length > 0) {
                    ws.send(JSON.stringify({ type: "error", payload: { message: "Room is full" } }));
                    return;
                }

                room.players.push({ id: data.id, score: 0, turn: false });
                await room.save();
                if (room.players.length == 1) {
                  for(let client of clients)
                    client[1].send(JSON.stringify({ type: "start game",payload: { owner: room.owner, players: room.players }  }));
                    return;
                }
                for(let client of clients)
                    client[1].send(JSON.stringify({ type: "party_joined", payload: { owner: room.owner, players: room.players } }));
            }
            else if(data.type== "play_turn")
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
        else if(data.type=="send svg")
         {
              try {
            const id = data.id // Récupérer l'ID du joueur et l'image
            const svg = data.svg
    
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
                        type: "send svg",
                        svg: svg,
                        sid:id
                    }));
                }
            });
    
          } catch (error) {
             console.error("Erreur lors de la mise à jour de l'image :", error);
             clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "Erreur serveur" } }));
          }
        
        }
        else if(data.type=="guess")
         {
                
           try {
            const { id, guess } = data; // Récupérer l'ID du joueur et le mot deviné
            console.log(guess)
    
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
            if (room.prompt === data.guess) {
                console.log(data.guess)
                // Incrémenter le score du joueur gagnant
                console.log('qqqqqqqqqqqqqqqqqqqqq')
    
                // Notifier tout le monde que le joueur a trouvé la bonne réponse
                players.forEach(player => {
                    
                        const playerWs = clients.get(player.id);
                        if (playerWs) {
                            playerWs.send(JSON.stringify({ 
                                type: "player_won", 
                                id:id
                            }));
                        }
                    
                });

                return
                // Passer le tour au joueur suivant
                /*const currentTurnIndex = players.findIndex(player => player.turn);
                players[currentTurnIndex].turn = false;
    
                const nextTurnIndex = (currentTurnIndex + 1) % players.length;
                players[nextTurnIndex].turn = true;
    
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

                // Notifier les joueurs le tour suivant
                for(let client of clients) {
                    client[1].get(players[nextTurnIndex].id)?.send(JSON.stringify({
                        type: "your_turn",
                        data: { nextTurn: players[nextTurnIndex].id }
                    }));
                }
    
                // Vérifier si on est au dernier tour (retour au premier joueur)
                
    
                // Sauvegarder les modifications
                await room.save();*/
            } else {
                // Mauvaise réponse
                ws.send(JSON.stringify({ type: "wrong_guess", id:id }));
            }
    
            } catch (error) {
               console.error("Erreur lors du traitement du guess :", error);
               clients.get(ws.id)?.send(JSON.stringify({ type: "error", data: { message: "Erreur serveur" } }));
            }
          }
    
        else if (data.type=="timeout")
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
            // if (!players[currentPlayerIndex].turn) {
            //     ws.send(JSON.stringify({ type: "error", message: "Ce n'est pas votre tour" }));
            //     return;
            // }
    
            /*// Passer le tour au joueur suivant
            players[currentPlayerIndex].turn = false; // Retirer le tour du joueur actuel
            let nextPlayerIndex = (currentPlayerIndex + 1) % players.length; // Déterminer le joueur suivant
            players[nextPlayerIndex].turn = true; // Donner le tour au suivant
    
            // Informer le joueur suivant
            const nextPlayer = clients.get(players[nextPlayerIndex].id);
            for(let client of clients) {
                client[1].get(players[nextTurnIndex].id)?.send(JSON.stringify({
                    type: "your_turn",
                    data: { nextTurn: players[nextTurnIndex].id }
                }));
            }
    */
            // Mettre à jour le score du joueur qui a dépassé le temps
            
    
           
    
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
const PORT = 3000;
server.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
