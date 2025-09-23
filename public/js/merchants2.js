/* Merchants2.js */

// Game Constants
const COLORS = ['white', 'blue', 'red', 'green', 'yellow', 'brown'];
const SPECIAL_CARDS = {
    ship: { cost: 10, count: 14, name: 'Ship', description: 'Hold one more cube' },
    office: { cost: 15, count: 2, name: 'Office', description: '2 extra coins per delivery' },
    warehouse: { cost: 11, count: 2, name: 'Warehouse', description: 'Hand size +2' },
    customsHouse: { cost: 9, count: 2, name: 'Customs House', description: 'Draw +1 card' },
    crane: { cost: 12, count: 3, name: 'Crane', description: 'Exchange +1 cube' }
};
const MAX_HAND_SIZE = 8;
const STARTING_COINS = 5;
const STARTING_HAND_SIZE = 3;
const CUBES_PER_COLOR = 5;

// Game state
class Merchants {

    constructor() {
        this.players = [];
        this.currentPlayer = 0;
        this.phase = 1; // 1= Purchase/Exchange or Pass, 2= Deliver or Draw cards
        this.marketplace = [];
        this.deck = [];
        this.gameOver = false;
        this.gameSetup = true;
        this.cubeSupply = {};
        this.specialCards = { ...SPECIAL_CARDS };
    }

    initialiseCubeSupply() {
        this.cubeSupply = {};
        COLORS.forEach(color => {
            this.cubeSupply[color] = CUBES_PER_COLOR; // Only 5 cubes of each color
        });
    }

    initialiseDeck() {
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


}