// Merchants.js
// 

// Game Constants
const COLORS = ['white', 'blue', 'red', 'green', 'yellow', 'brown'];
const SPECIAL_CARDS = {
    ship: { cost: 10, count: 14 },
    office: { cost: 8, count: 2 },
    warehouse: { cost: 15, count: 2 },
    forklift: { cost: 15, count: 2 },
    crane: { cost: 12, count: 2 }
};
const MAX_HAND_SIZE = 8;
const STARTING_COINS = 5;
const STARTING_HAND_SIZE = 3;


// Game Model
class MerchantsGame {
    constructor() {
        this.players = [];
        this.currentPlayer = 0;
        this.phase = 1; // 1 = Purchase, 2 = Deliver
        this.marketplace = [];
        this.deck = [];
        this.specialCards = { ...SPECIAL_CARDS };
        this.cubeSupply = {};
        this.gameEnded = false;
        
        this.initializeCubeSupply();
        this.initializeDeck();
        this.initializePlayers(3); // Default 3 players
        this.setupGame();
    }

    initializeCubeSupply() {
        this.cubeSupply = {};
        COLORS.forEach(color => {
            this.cubeSupply[color] = 5; // Only 5 cubes of each color
        });
    }

    initializeDeck() {
        this.deck = [];
        COLORS.forEach(color => {
            for (let i = 0; i < 10; i++) {
                this.deck.push({ color, id: `${color}_${i}` });
            }
        });
        this.shuffleDeck();
    }

    shuffleDeck() {
        for (let i = this.deck.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [this.deck[i], this.deck[j]] = [this.deck[j], this.deck[i]];
        }
    }

    initializePlayers(count) {
        this.players = [];
        for (let i = 0; i < count; i++) {
            this.players.push({
                id: i,
                name: `Player ${i + 1}`,
                coins: 0,
                hand: [],
                ships: [
                    { cube: null },
                    { cube: null }
                ],
                specialCards: [],
                handLimit: 6
            });
        }
    }

    setupGame() {
        // Deal 3 cards to each player
        this.players.forEach(player => {
            for (let i = 0; i < 3; i++) {
                if (this.deck.length > 0) {
                    player.hand.push(this.deck.pop());
                }
            }
        });

        // Create marketplace
        this.marketplace = [];
        for (let i = 0; i < 6; i++) {
            if (this.deck.length > 0) {
                this.marketplace.push(this.deck.pop());
            }
        }

        // Snake draft for initial cubes
        this.snakeDraftCubes();
    }

    snakeDraftCubes() {
        // Snake draft: last player picks first, then clockwise, then reverse
        const draftOrder = [];
        const numPlayers = this.players.length;
        
        // Create snake order for 2 rounds
        for (let round = 0; round < 2; round++) {
            if (round % 2 === 0) {
                // Forward order (last to first)
                for (let i = numPlayers - 1; i >= 0; i--) {
                    draftOrder.push(i);
                }
            } else {
                // Reverse order (first to last)
                for (let i = 0; i < numPlayers; i++) {
                    draftOrder.push(i);
                }
            }
        }
        
        // Execute the draft
        draftOrder.forEach((playerIndex, draftIndex) => {
            const availableColors = COLORS.filter(color => this.cubeSupply[color] > 0);
            
            if (availableColors.length > 0) {
                // For demo, pick randomly. In real game, players would choose
                const randomIndex = Math.floor(Math.random() * availableColors.length);
                const chosenColor = availableColors[randomIndex];
                
                // Find next available ship slot for this player
                const player = this.players[playerIndex];
                const emptyShipIndex = player.ships.findIndex(ship => !ship.cube);
                
                if (emptyShipIndex !== -1) {
                    player.ships[emptyShipIndex].cube = { color: chosenColor };
                    this.cubeSupply[chosenColor]--;
                }
            }
        });
    }

    drawCard() {
        return this.deck.length > 0 ? this.deck.pop() : null;
    }

    nextPhase() {
        if (this.phase === 1) {
            this.phase = 2;
        } else {
            this.phase = 1;
            this.nextPlayer();
        }
    }

    nextPlayer() {
        this.currentPlayer = (this.currentPlayer + 1) % this.players.length;
    }

    makeDelivery(cardIndices) {
        const player = this.players[this.currentPlayer];
        const cardsToPlay = cardIndices.map(i => player.hand[i]);
        
        if (cardsToPlay.length === 0) return false;
        
        // Check all cards are same color
        const color = cardsToPlay[0].color;
        if (!cardsToPlay.every(card => card.color === color)) return false;

        // Remove cards from hand
        cardIndices.sort((a, b) => b - a).forEach(i => {
            player.hand.splice(i, 1);
        });

        // Add to marketplace (simplified - just add to end)
        cardsToPlay.forEach(card => {
            this.marketplace.push(card);
        });

        // Calculate payouts
        const colorCount = this.marketplace.filter(card => card.color === color).length;
        this.players.forEach(p => {
            const cubes = p.ships.filter(ship => ship.cube && ship.cube.color === color).length;
            let payout = cubes * cardsToPlay.length;
            
            // Office bonus
            if (p.specialCards.includes('office')) {
                payout += 2 * cardsToPlay.length;
            }
            
            p.coins += payout;
        });

        return true;
    }

    drawCards(count = 2) {
        const player = this.players[this.currentPlayer];
        let drawn = 0;
        
        // Forklift bonus
        if (player.specialCards.includes('forklift')) {
            count += 1;
        }
        
        while (drawn < count && this.deck.length > 0 && player.hand.length < player.handLimit) {
            player.hand.push(this.drawCard());
            drawn++;
        }
        
        return drawn;
    }

    exchangeCube(shipIndex, newColor) {
        const player = this.players[this.currentPlayer];
        
        if (shipIndex >= 0 && shipIndex < player.ships.length && player.ships[shipIndex].cube) {
            const oldColor = player.ships[shipIndex].cube.color;
            
            // Check if new color is available in supply
            if (this.cubeSupply[newColor] > 0) {
                // Return old cube to supply
                this.cubeSupply[oldColor]++;
                
                // Take new cube from supply
                this.cubeSupply[newColor]--;
                player.ships[shipIndex].cube = { color: newColor };
                
                return true;
            }
        }
        return false;
    }

    buySpecialCard(type) {
        const player = this.players[this.currentPlayer];
        const card = SPECIAL_CARDS[type];
        
        if (this.specialCards[type].count > 0 && player.coins >= card.cost) {
            player.coins -= card.cost;
            player.specialCards.push(type);
            this.specialCards[type].count--;
            
            // Apply immediate effects
            if (type === 'ship') {
                player.ships.push({ cube: { color: COLORS[Math.floor(Math.random() * COLORS.length)] } });
            } else if (type === 'warehouse') {
                player.handLimit += 2;
            }
            
            return true;
        }
        return false;
    }

    checkGameEnd() {
        if (this.deck.length === 0) {
            this.gameEnded = true;
            return true;
        }
        return false;
    }

    getWinner() {
        return this.players.reduce((winner, player) => 
            player.coins > winner.coins ? player : winner, this.players[0]);
    }
}

// UI Controller
class GameUI {
    constructor() {
        this.game = new GameState();
        this.selectedCards = [];
        this.setupEventListeners();
        this.render();
    }

    setupEventListeners() {
        document.getElementById('exchangeBtn').addEventListener('click', () => this.handleExchange());
        document.getElementById('buySpecialBtn').addEventListener('click', () => this.handleBuySpecial());
        document.getElementById('passBtn').addEventListener('click', () => this.handlePass());
        document.getElementById('deliverBtn').addEventListener('click', () => this.handleDeliver());
        document.getElementById('drawBtn').addEventListener('click', () => this.handleDraw());
        document.getElementById('nextPhaseBtn').addEventListener('click', () => this.handleNextPhase());
    }

    render() {
        this.renderMarketplace();
        this.renderPlayers();
        this.renderGameInfo();
        this.updateButtons();
    }

    renderMarketplace() {
        const marketplace = document.getElementById('marketplace');
        marketplace.innerHTML = '';
        
        this.game.marketplace.forEach((card, index) => {
            const cardEl = document.createElement('div');
            cardEl.className = `card ${card.color}`;
            cardEl.textContent = card.color.charAt(0).toUpperCase();
            marketplace.appendChild(cardEl);
        });
    }

    renderPlayers() {
        const playersArea = document.getElementById('playersArea');
        playersArea.innerHTML = '';
        
        this.game.players.forEach((player, index) => {
            const playerEl = document.createElement('div');
            playerEl.className = `player ${index === this.game.currentPlayer ? 'active' : ''}`;
            
            playerEl.innerHTML = `
                <div class="player-info">
                    <h3>${player.name}</h3>
                    <div class="coins">${player.coins} coins</div>
                </div>
                <div class="ships">
                    ${player.ships.map((ship, shipIndex) => `
                        <div class="ship">
                            ${ship.cube ? `<div class="cube ${ship.cube.color}"></div>` : ''}
                        </div>
                    `).join('')}
                </div>
                <div class="special-cards">
                    ${player.specialCards.map(card => `
                        <div class="special-card">${card}</div>
                    `).join('')}
                </div>
                <div class="hand">
                    <div>Hand: ${player.hand.length}/${player.handLimit}</div>
                    ${index === this.game.currentPlayer ? `
                        <div class="hand-cards">
                            ${player.hand.map((card, cardIndex) => `
                                <div class="card ${card.color}" data-card-index="${cardIndex}">
                                    ${card.color.charAt(0).toUpperCase()}
                                </div>
                            `).join('')}
                        </div>
                    ` : ''}
                </div>
            `;
            
            playersArea.appendChild(playerEl);
        });
        
        // Add click listeners to current player's hand
        document.querySelectorAll('.hand-cards .card').forEach(cardEl => {
            cardEl.addEventListener('click', (e) => {
                const cardIndex = parseInt(e.target.dataset.cardIndex);
                this.toggleCardSelection(cardIndex, e.target);
            });
        });
    }

    renderGameInfo() {
        document.getElementById('phaseIndicator').textContent = 
            `Phase ${this.game.phase}: ${this.game.phase === 1 ? 'Purchase' : 'Deliver'}`;
        document.getElementById('cardsRemaining').textContent = this.game.deck.length;
    }

    updateButtons() {
        const phase1Buttons = ['exchangeBtn', 'buySpecialBtn', 'passBtn'];
        const phase2Buttons = ['deliverBtn', 'drawBtn'];
        
        phase1Buttons.forEach(id => {
            document.getElementById(id).style.display = this.game.phase === 1 ? 'inline-block' : 'none';
        });
        
        phase2Buttons.forEach(id => {
            document.getElementById(id).style.display = this.game.phase === 2 ? 'inline-block' : 'none';
        });
        
        // Enable/disable based on game state
        document.getElementById('deliverBtn').disabled = this.selectedCards.length === 0;
    }

    toggleCardSelection(cardIndex, cardEl) {
        const index = this.selectedCards.indexOf(cardIndex);
        if (index > -1) {
            this.selectedCards.splice(index, 1);
            cardEl.style.border = '2px solid rgba(255, 255, 255, 0.3)';
        } else {
            this.selectedCards.push(cardIndex);
            cardEl.style.border = '2px solid #f39c12';
        }
        this.updateButtons();
    }

    handleExchange() {
        // Simplified - exchange first ship's cube to a random color
        const newColor = COLORS[Math.floor(Math.random() * COLORS.length)];
        this.game.exchangeCube(0, newColor);
        this.game.nextPhase();
        this.render();
    }

    handleBuySpecial() {
        // Simplified - try to buy ship if affordable
        if (this.game.buySpecialCard('ship')) {
            this.game.nextPhase();
            this.render();
        }
    }

    handlePass() {
        this.game.nextPhase();
        this.render();
    }

    handleDeliver() {
        if (this.selectedCards.length > 0) {
            this.game.makeDelivery(this.selectedCards);
            this.selectedCards = [];
            this.game.nextPhase();
            this.render();
        }
    }

    handleDraw() {
        this.game.drawCards();
        this.game.nextPhase();
        this.render();
    }

    handleNextPhase() {
        this.game.nextPhase();
        this.render();
    }
}

// Start the game
window.onload = () => {
    new GameUI();
};