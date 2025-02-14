const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");
const mongoose = require("mongoose");

const Item = require("./models/Item");
const Prompt = require("./models/prompt");
const Party=require("./models/party")
const Room=require("./models/room")

const app = express();
const server = http.createServer(app);

mongoose.connect("mongodb://admin:secret@localhost:27017/mydb?authSource=admin", {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
.then(() => {console.log("✅ Connecté à MongoDB")
insertPrompts();})
.catch(err => console.error("❌ Erreur de connexion à MongoDB", err));


const promptsData = [
    
    { prompt: "Helicopter", action: "Medium" },
    { prompt: "Computer", action: "Hard" },
    { prompt: "Cat", action: "Easy" },
    { prompt: "Mountain", action: "Medium" },
    { prompt: "Robot", action: "Hard" },
    { prompt: "Sun", action: "Easy" },
    { prompt: "Airplane", action: "Medium" },
    { prompt: "Castle", action: "Hard" },
    { prompt: "Fish", action: "Easy" },
    { prompt: "Bicycle", action: "Medium" },
    { prompt: "Spaceship", action: "Hard" },
    { prompt: "Tree", action: "Easy" },
    { prompt: "Bridge", action: "Medium" },
    { prompt: "Dragon", action: "Hard" },
    { prompt: "Car", action: "Easy" },
    { prompt: "Train", action: "Medium" },
    { prompt: "Portrait", action: "Hard" },
    { prompt: "Apple", action: "Easy" },
    { prompt: "Clock", action: "Medium" },
    { prompt: "Eagle", action: "Hard" },
    { prompt: "House", action: "Easy" },
    { prompt: "Ship", action: "Medium" },
    { prompt: "Galaxy", action: "Hard" },
    { prompt: "Leaf", action: "Easy" },
    { prompt: "Guitar", action: "Medium" },
    { prompt: "Tiger", action: "Hard" },
    { prompt: "Candle", action: "Easy" },
    { prompt: "Windmill", action: "Medium" },
    { prompt: "Knight", action: "Hard" }
];

async function insertPrompts() {
    try {
        for (const promptData of promptsData) {
            await Prompt.updateOne(
                { prompt: promptData.prompt }, // Condition pour trouver un document existant
                { $set: promptData }, // Mise à jour ou insertion
                { upsert: true } // Insère si le document n'existe pas
            );
        }
        console.log("✅ Prompts insérés ou mis à jour avec succès !");
    
    } catch (error) {
        console.error("❌ Erreur lors de l'insertion :", error.message);
        mongoose.connection.close();
    }
}






// Ajout de CORS pour Express
app.use(cors({
    origin: "*",  
    methods: ["GET", "POST"],
    allowedHeaders: ["Content-Type"]
}));

// Ajout de CORS pour Socket.IO
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Middleware JSON
app.use(express.json());

// Route principale
app.get("/", (req, res) => {
    res.send("Hello, Express avec Socket.IO!");
});

// Gestion des connexions Socket.IO
io.on("connection", (socket) => {
    console.log(`Un utilisateur connecté : ${socket.id}`);
    const id = socket.id;

    socket.on("send_data", async (data) => {
        console.log(`Message reçu : ${data}`);
        const { time, accuracy, action } = data;

        // Simulation de la réponse Flask
        

        let item = await Item.findOne({ id }); // Recherche dans la base de données
        console.log("hi")
        if (!item) {
            item = new Item({ id, level:0 }); // Crée un nouvel élément
            await item.save();
        }

        console.log(item)
        let level=item.level
        const response = { level:0, newActionction: "Medium" }; 

        console.log("Réponse simulée du serveur Flask:", response);
        let { newAction } = response;
        level=response.level
        // Ancienne requête vers Flask (désactivée)
        /*
        axios.post("http://localhost:5000/api/receive", data)
        .then(async (response) => {
        */

         
        await Item.findOneAndUpdate(
                { id },  // Condition pour trouver l'élément
                { level },  // Champs à mettre à jour
                { new: true } // Retourne l'élément mis à jour
            );
        

        console.log(action)
        const prompts = await Prompt.find({ newAction }).select("prompt -_id");
        console.log(prompts)
        const randomIndex = Math.floor(Math.random() * prompts.length);
        const responseData = { level, prompt: prompts[randomIndex] };

        io.emit("message", responseData);
        
        // Ancienne gestion d'erreur Axios (désactivée)
        /*
        })
        .catch(error => {
            console.error("Erreur lors de la requête:", error.message);
        });
        */
    }
    
);

    socket.on("play_vs_1",async(data)=>{
        let item = await Item.findOne({ id }); // Recherche dans la base de données
        console.log("hi")
        if (!item) {
            item = new Item({ id, level:0 }); // Crée un nouvel élément
            await item.save();
        }
        await Item.findOneAndUpdate(
            { id },  // Condition pour trouver l'élément
            { level },  // Champs à mettre à jour
            { new: true } // Retourne l'élément mis à jour
        );

        let item2= await Item.findOne({level,id: { $ne: id }} )
        if(item2) return
        let party=await Party.create({id1:item.id,id2:item2.id})
        io.emit("1vs_response",{party})
        io.to(item2.id).emit("1vs_response", { party });

    })

    socket.on("create_room",async(data)=>{

        console.log(id)
        const random = Math.floor(100000 + Math.random() * 900000).toString();
        const room = await Room.create({ owner: { id, score: 0, turn: true }, code: random });
        console.log(room)
        io.emit("party_created", { code: random });
        
    })

    socket.on("join_room",async(data)=>{

        const {code}=data
        const room=await Room.findOne({code})
       if(!room)
        { 
            io.emit("error",{})
            return
        }
        if (room.owner.id === id || room.players.some(player => player.id === id)) {
            io.emit("error",{})
            return
        }

        // Vérifier si la salle est pleine (max 3 joueurs + owner)
        if (room.players.length >= 3) {
            io.emit("error",{})
            return
        }

        // Ajouter le joueur à la salle
        room.players.push({ id, score: 0, turn: false });

        // Sauvegarder les modifications
        await room.save();
        io.emit("party_joined",{owner:room.owner,players:room.players})
    })

    socket.on("play_turn", async (data) => {
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
                socket.emit("error", { message: "Salle introuvable" });
                return;
            }
    
            // Récupérer tous les joueurs (y compris l'owner)
            let players = [room.owner, ...room.players];
    
            // Trouver le joueur actuel
            const currentPlayer = players.find(player => player.id === id);
            if (!currentPlayer) {
                socket.emit("error", { message: "Joueur non trouvé dans la salle" });
                return;
            }
    
            // Vérifier si c'est son tour
            if (!currentPlayer.turn) {
                socket.emit("error", { message: "Ce n'est pas votre tour" });
                return;
            }
    
            // Mettre à jour le prompt de la partie
            room.prompt = prompt;
            await room.save();
    
            // Notifier tous les autres joueurs que le jeu a commencé
            players.forEach(player => {
                if (player.id !== id) {
                    io.to(player.id).emit("launched_game", { prompt });
                }
            });
    
        } catch (error) {
            console.error("Erreur lors du lancement du tour :", error);
            socket.emit("error", { message: "Erreur serveur" });
        }
    });
    

    socket.on("update_image", async (data) => {
        try {
            const { id, image } = data; // Récupération de l'ID du joueur et de l'image
    
            // Trouver la salle contenant le joueur ou le propriétaire
            const room = await Room.findOne({
                $or: [
                    { "owner.id": id },
                    { "players.id": id }
                ]
            });
    
            if (!room) {
                socket.emit("error", { message: "Salle introuvable" });
                return;
            }
    
            // Récupérer tous les joueurs (y compris l'owner)
            let players = [room.owner, ...room.players];
    
            // Trouver le joueur actuel
            const currentPlayer = players.find(player => player.id === id);
            if (!currentPlayer) {
                socket.emit("error", { message: "Joueur non trouvé dans la salle" });
                return;
            }
    
            // Vérifier si c'est son tour
            if (!currentPlayer.turn) {
                socket.emit("error", { message: "Ce n'est pas votre tour" });
                return;
            }
    
            // Envoyer l'image à tous les autres joueurs
            players.forEach(player => {
                if (player.id !== id) {
                    io.to(player.id).emit("updated_image", { image });
                }
            });
    
        } catch (error) {
            console.error("Erreur lors de la mise à jour de l'image :", error);
            socket.emit("error", { message: "Erreur serveur" });
        }
    });
    

    socket.on("guess", async (data) => {
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
                socket.emit("error", { message: "Salle introuvable" });
                return;
            }
    
            // Récupérer tous les joueurs (y compris l'owner)
            let players = [room.owner, ...room.players];
    
            // Trouver l'index du joueur actuel
            const currentPlayerIndex = players.findIndex(player => player.id === id);
            if (currentPlayerIndex === -1) {
                socket.emit("error", { message: "Joueur non trouvé dans la salle" });
                return;
            }
    
            // Vérifier si ce n'est PAS son tour (car il doit deviner, pas jouer)
            if (players[currentPlayerIndex].turn) {
                socket.emit("error", { message: "C'est votre tour, vous ne pouvez pas deviner" });
                return;
            }
    
            // Vérifier si la réponse est correcte
            if (room.prompt === prompt) {
                // Incrémenter le score du joueur gagnant
                players[currentPlayerIndex].score += 1;
    
                // Notifier tout le monde que le joueur a trouvé la bonne réponse
                players.forEach(player => {
                    io.to(player.id).emit("player_won", { id, message: `Le joueur ${id} a trouvé la bonne réponse !` });
                });
    
                // Passer le tour au joueur suivant
                const currentTurnIndex = players.findIndex(player => player.turn);
                players[currentTurnIndex].turn = false;
    
                const nextTurnIndex = (currentTurnIndex + 1) % players.length;
                players[nextTurnIndex].turn = true;
    
                // Notifier le joueur suivant que c'est son tour
                io.to(players[nextTurnIndex].id).emit("your_turn", { message: "C'est votre tour !" });
    
                // Vérifier si on est au dernier tour (retour au premier joueur)
                if (nextTurnIndex === 0) {
                    const winner = players.reduce((best, player) => (player.score > best.score ? player : best), players[0]);
    
                    // Envoyer les scores finaux à chaque joueur
                    players.forEach(player => {
                        io.to(player.id).emit("game_over", {
                            message: "Fin du jeu",
                            scores: players.map(p => ({ id: p.id, score: p.score })),
                            winner: { id: winner.id, score: winner.score }
                        });
                    });
                }
    
                // Sauvegarder les modifications
                await room.save();
            } else {
                // Mauvaise réponse
                socket.emit("wrong_guess", { message: "Mauvaise réponse, réessayez !" });
            }
    
        } catch (error) {
            console.error("Erreur lors du traitement du guess :", error);
            socket.emit("error", { message: "Erreur serveur" });
        }
    });
    

    socket.on("timeout", async (data) => {
        try {
            const id = socket.id; // ID du joueur qui a dépassé le temps
    
            // Trouver la salle où ce joueur est owner ou player
            const room = await Room.findOne({
                $or: [
                    { "owner.id": id },
                    { "players.id": id }
                ]
            });
    
            if (!room) {
                socket.emit("error", { message: "Salle introuvable" });
                return;
            }
    
            // Récupérer tous les joueurs (y compris l'owner)
            let players = [room.owner, ...room.players];
    
            // Trouver l'index du joueur actuel
            let currentPlayerIndex = players.findIndex(player => player.id === id);
    
            if (currentPlayerIndex === -1) {
                socket.emit("error", { message: "Joueur non trouvé dans la salle" });
                return;
            }
    
            // Vérifier si c'est bien SON tour
            if (!players[currentPlayerIndex].turn) {
                socket.emit("error", { message: "Ce n'est pas votre tour" });
                return;
            }
    
            // Passer le tour au joueur suivant
            players[currentPlayerIndex].turn = false; // Retirer le tour du joueur actuel
            let nextPlayerIndex = (currentPlayerIndex + 1) % players.length; // Tour suivant
            players[nextPlayerIndex].turn = true; // Donner le tour au suivant
    
            // Informer le joueur suivant
            io.to(players[nextPlayerIndex].id).emit("your_turn", { message: "C'est votre tour !" });
    
            // Mettre à jour le score du joueur qui a dépassé le temps
            players[currentPlayerIndex].score += 1;
    
            // Sauvegarder les modifications
            await room.save();
    
            // Informer tous les autres joueurs
            players.forEach(player => {
                if (player.id !== id) {
                    io.to(player.id).emit("time_finished", { message: `Le joueur ${id} a perdu son tour.` });
                }
            });
    
        } catch (error) {
            console.error("Erreur lors du changement de tour :", error);
            socket.emit("error", { message: "Erreur serveur" });
        }
    });
    
    
    socket.on("disconnect", () => {
        console.log(`Utilisateur déconnecté : ${socket.id}`);
    });


});

// Démarrer le serveur
const PORT = 3000;
server.listen(PORT, () => {
    console.log(`Serveur WebSocket démarré sur http://localhost:${PORT}`);
});
